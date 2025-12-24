# Fase 2 — Ejemplo guiado de Modelado Predictivo con BigQuery ML (NYC Taxi 2022)


---

## 0) Requisitos previos

* Proyecto GCP activo y **BigQuery** habilitado.
* Repositorio con la **Fase_1** ya completada, incluyendo tablas optimizadas (ej.: `trips_q1_clean`, `hourly_demand_q1`, `monthly_metrics_q1`, `tips_buckets_q1`).
* Dataset de trabajo (ej.):

  * `ss2-bigquery-team0.fase1_dataset` (Fase 1)
  * `ss2-bigquery-team0.fase2_dataset` (Fase 2; se crea en este README)
* Regla de oro Fase 2: **El modelado principal se ejecuta en BigQuery ML**. Herramientas externas (Colab, PySpark, scikit‑learn) son **apoyo opcional**, no sustituyen BQML.

---

## 1) Preparación de entorno Fase 2

### 1.1 Crear dataset de trabajo (Fase 2)

```sql
CREATE SCHEMA IF NOT EXISTS `ss2-bigquery-team0.fase2_dataset`
OPTIONS (location = "US");
```

> Puedes trabajar también en el dataset de Fase 1. Separarlo ayuda a **organizar evidencias** (entrenamiento, métricas, predicciones) sin mezclar con tablas derivadas exploratorias.

### 1.2 Nomenclatura sugerida

* Modelos: `fase2_<tarea>_<algoritmo>`
  Ej.: `fase2_tipped_logistic`, `fase2_tipped_btree`
* Tablas de salida: `pred_<tarea>_<algoritmo>`, `eval_<tarea>_<algoritmo>`

---

## 2) Selección del problema y variable objetivo

Proponemos un caso **de clasificación binaria**: predecir si habrá **propina** (`tipped = 1`) en un viaje.
Alternativamente, puedes implementar también **regresión** sobre `tip_amount` para comparar enfoques.

* **Objetivo (clasificación):** `tipped` = `tip_amount > 0`
* **Métrica primaria:** `AUC_ROC` (área bajo la curva), con secundarias como `accuracy`, `precision`, `recall`, `log_loss`.

> **TODO del estudiante:** justificar por qué esta tarea aporta valor (negocio: incentivar promociones por horario/zona con mayor probabilidad de propina, etc.).

---

## 3) Preparación de features (ingeniería de variables)

Partimos de `fase1_dataset.trips_q1_clean` (particionada por fecha). Generamos **features temporales y categóricas** comunes para propensión a propina.

```sql
CREATE OR REPLACE TABLE `ss2-bigquery-team0.fase2_dataset.trips_q1_features`
PARTITION BY DATE(pickup_datetime)
CLUSTER BY pickup_location_id AS
SELECT
  -- Label
  CASE WHEN tip_amount > 0 THEN 1 ELSE 0 END AS tipped,
  -- Señales temporales
  EXTRACT(HOUR FROM pickup_datetime) AS hour_of_day,
  EXTRACT(DAYOFWEEK FROM pickup_datetime) AS dow,         -- 1=Domingo
  EXTRACT(DAY FROM pickup_datetime) AS day,
  EXTRACT(MONTH FROM pickup_datetime) AS month,
  -- Magnitudes
  trip_distance,
  total_amount,
  fare_amount,
  passenger_count,
  -- Señales de ubicación (como claves categóricas)
  CAST(pickup_location_id AS STRING) AS pickup_loc,
  CAST(dropoff_location_id AS STRING) AS dropoff_loc,
  -- Conservamos timestamp para partición/segmentación
  pickup_datetime
FROM `ss2-bigquery-team0.fase1_dataset.trips_q1_clean`
WHERE DATE(pickup_datetime) BETWEEN '2022-01-01' AND '2022-03-31'
  AND trip_distance > 0
  AND total_amount >= 0
  AND fare_amount >= 0
  AND passenger_count BETWEEN 1 AND 6;
```

> **Buenas prácticas**: sin `SELECT *`; solo columnas necesarias. Filtra por la **columna de partición** para minimizar bytes.

**Opcional** (mejora de features):

* `tip_rate = SAFE_DIVIDE(tip_amount, NULLIF(total_amount,0))` (solo para **regresión**; no usar en clasificación porque usa el objetivo).
* Interacciones simples (ej.: `is_weekend = dow IN (1,7)`).
* Binning por distancia (`CASE WHEN trip_distance <= 2 THEN 'corta' ...`).

> **TODO del estudiante:** añadir al menos **2 features** nuevas justificadas.

---

## 4) Estrategia de división Train/Test

Para evitar *leakage* temporal en Q1, usaremos una división por **tiempo**:

* **Entrenamiento:** enero + febrero 2022
* **Prueba (holdout):** marzo 2022

Creamos **vistas** para facilitar filtros coherentes y reproducibles.

```sql
CREATE OR REPLACE VIEW `ss2-bigquery-team0.fase2_dataset.v_features_train` AS
SELECT *
FROM `ss2-bigquery-team0.fase2_dataset.trips_q1_features`
WHERE DATE(pickup_datetime) BETWEEN '2022-01-01' AND '2022-02-28';

CREATE OR REPLACE VIEW `ss2-bigquery-team0.fase2_dataset.v_features_test` AS
SELECT *
FROM `ss2-bigquery-team0.fase2_dataset.trips_q1_features`
WHERE DATE(pickup_datetime) BETWEEN '2022-03-01' AND '2022-03-31';
```

> **Alternativa**: división aleatoria con `RAND()` y proporción 80/20, **pero** la división temporal es más realista para series y evita fuga de información.

---

## 5) Entrenamiento con BigQuery ML (2 modelos mínimos)

### 5.1 Modelo A — **Regresión Logística** (clasificación)

```sql
CREATE OR REPLACE MODEL `ss2-bigquery-team0.fase2_dataset.fase2_tipped_logistic`
OPTIONS(
  MODEL_TYPE = 'LOGISTIC_REG',
  INPUT_LABEL_COLS = ['tipped'],
  AUTO_CLASS_WEIGHTS = TRUE,
  L1_REG = 0.0,
  L2_REG = 1.0
) AS
SELECT
  tipped,
  hour_of_day, dow, month,
  trip_distance, total_amount, fare_amount, passenger_count,
  pickup_loc, dropoff_loc
FROM `ss2-bigquery-team0.fase2_dataset.v_features_train`;
```

> **Nota**: BQML maneja codificación de categorías automáticamente (one‑hot interno o hash). Puedes controlar con `category_encoding_method` si lo necesitas.

### 5.2 Modelo B — **Árbol Potenciado** (Boosted Tree Classifier)

```sql
CREATE OR REPLACE MODEL `ss2-bigquery-team0.fase2_dataset.fase2_tipped_btree`
OPTIONS(
  MODEL_TYPE = 'BOOSTED_TREE_CLASSIFIER',
  INPUT_LABEL_COLS = ['tipped'],
  NUM_PARALLEL_TREE = 1,
  MAX_TREE_DEPTH = 6,
  SUBSAMPLE = 0.8,
  NUM_BOOSTER_ROUND = 30,
  MIN_TREE_CHILD_WEIGHT = 1
) AS
SELECT
  tipped,
  hour_of_day, dow, month,
  trip_distance, total_amount, fare_amount, passenger_count,
  pickup_loc, dropoff_loc
FROM `ss2-bigquery-team0.fase2_dataset.v_features_train`;
```

> **TODO del estudiante (tuning)**: experimentar con `MAX_TREE_DEPTH`, `NUM_BOOSTER_ROUND`, `SUBSAMPLE` y documentar cómo cambian las métricas.

### 5.3 Evidencia de entrenamiento

```sql
-- Información del entrenamiento
SELECT *
FROM ML.TRAINING_INFO(MODEL `ss2-bigquery-team0.fase2_dataset.fase2_tipped_logistic`);

SELECT *
FROM ML.TRAINING_INFO(MODEL `ss2-bigquery-team0.fase2_dataset.fase2_tipped_btree`);
```

Captura en **Job Information**: tiempos, bytes, etc. (guía en Fase 1).

---

## 6) Evaluación de modelos (set de prueba)

```sql
-- LOGISTIC
CREATE OR REPLACE TABLE `ss2-bigquery-team0.fase2_dataset.eval_tipped_logistic` AS
SELECT *
FROM ML.EVALUATE(
  MODEL `ss2-bigquery-team0.fase2_dataset.fase2_tipped_logistic`,
  (
    SELECT
      tipped,
      hour_of_day, dow, month,
      trip_distance, total_amount, fare_amount, passenger_count,
      pickup_loc, dropoff_loc
    FROM `ss2-bigquery-team0.fase2_dataset.v_features_test`
  )
);

-- BOOSTED TREE
CREATE OR REPLACE TABLE `ss2-bigquery-team0.fase2_dataset.eval_tipped_btree` AS
SELECT *
FROM ML.EVALUATE(
  MODEL `ss2-bigquery-team0.fase2_dataset.fase2_tipped_btree`,
  (
    SELECT
      tipped,
      hour_of_day, dow, month,
      trip_distance, total_amount, fare_amount, passenger_count,
      pickup_loc, dropoff_loc
    FROM `ss2-bigquery-team0.fase2_dataset.v_features_test`
  )
);
```

**Tabla comparativa rápida**

```sql
SELECT 'LOGISTIC' AS model,
       roc_auc, accuracy, precision, recall, f1_score, log_loss
FROM `ss2-bigquery-team0.fase2_dataset.eval_tipped_logistic`
UNION ALL
SELECT 'BTREE' AS model,
       roc_auc, accuracy, precision, recall, f1_score, log_loss
FROM `ss2-bigquery-team0.fase2_dataset.eval_tipped_btree`
ORDER BY model;
```

> **TODO del estudiante:** elegir **métrica principal** (p. ej., `roc_auc`) y justificar la **selección del modelo final** con base en métricas + interpretabilidad.

---

## 7) Predicciones y tablas para el dashboard

```sql
-- Predicciones con el mejor modelo (ej.: BTREE)
CREATE OR REPLACE TABLE `ss2-bigquery-team0.fase2_dataset.pred_tipped_btree_test` AS
SELECT
  p.* EXCEPT (predicted_tipped),
  p.predicted_tipped AS tipped_pred,            -- clase predicha (0/1)
  p.predicted_tipped_probs[OFFSET(1)] AS p_yes, -- probabilidad de tipped=1
  f.pickup_datetime,
  f.pickup_loc, f.dropoff_loc, f.hour_of_day, f.dow, f.month,
  f.trip_distance, f.total_amount, f.fare_amount, f.passenger_count,
  f.tipped AS tipped_real
FROM ML.PREDICT(
  MODEL `ss2-bigquery-team0.fase2_dataset.fase2_tipped_btree`,
  (
    SELECT
      tipped,
      hour_of_day, dow, month,
      trip_distance, total_amount, fare_amount, passenger_count,
      pickup_loc, dropoff_loc
    FROM `ss2-bigquery-team0.fase2_dataset.v_features_test`
  )
) AS p
JOIN `ss2-bigquery-team0.fase2_dataset.v_features_test` AS f
ON TRUE
QUALIFY ROW_NUMBER() OVER () = ROW_NUMBER() OVER (); -- empareja filas 1:1
```

> La unión 1:1 por posición se asegura con `QUALIFY` para evitar *cross join* multiplicativo (misma cardinalidad de entrada/salida). Alternativamente, añade un `row_id` determinístico en `features` y úsalo para `JOIN`.

**Curvas y cortes de decisión**

```sql
-- Curva precisión/recall por umbral
SELECT *
FROM ML.ROC_CURVE(
  MODEL `ss2-bigquery-team0.fase2_dataset.fase2_tipped_btree`,
  TABLE `ss2-bigquery-team0.fase2_dataset.v_features_test`
);
```

> **TODO del estudiante:** proponer un **umbral** alternativo (≠ 0.5) para mejorar `precision` o `recall` según objetivo de negocio.

---

## 8) (Opcional) Regresión de monto de propina

Para comparar paradigmas, puedes entrenar **regresión** sobre `tip_amount`.

```sql
CREATE OR REPLACE MODEL `ss2-bigquery-team0.fase2_dataset.fase2_tipamount_linreg`
OPTIONS(
  MODEL_TYPE = 'LINEAR_REG',
  INPUT_LABEL_COLS = ['tip_amount']
) AS
SELECT
  tip_amount,
  hour_of_day, dow, month,
  trip_distance, total_amount, fare_amount, passenger_count,
  pickup_loc, dropoff_loc
FROM `ss2-bigquery-team0.fase2_dataset.v_features_train`;

CREATE OR REPLACE TABLE `ss2-bigquery-team0.fase2_dataset.eval_tipamount_linreg` AS
SELECT *
FROM ML.EVALUATE(
  MODEL `ss2-bigquery-team0.fase2_dataset.fase2_tipamount_linreg`,
  (
    SELECT
      tip_amount,
      hour_of_day, dow, month,
      trip_distance, total_amount, fare_amount, passenger_count,
      pickup_loc, dropoff_loc
    FROM `ss2-bigquery-team0.fase2_dataset.v_features_test`
  )
);
```

> Métricas: `rmse`, `mae`, `r2_score`.

---

## 9) Dashboard en Looker Studio / Sheets (Reales vs. Predichos)

Conecta `fase2_dataset.pred_tipped_btree_test` y crea:

* **KPI**: AUC, accuracy del modelo final (puedes “pegar” valores de la tabla `eval_*`).
* **Comparación real vs. predicho**: barras apiladas por `dow`, `hour_of_day`, `pickup_loc`.
* **Probabilidad media por segmento**: `AVG(p_yes)` por `hour_of_day`/`pickup_loc`.
* **Error por segmento**: `AVG(ABS(tipped_real - tipped_pred))` por `dow`.

> **Rendimiento**: limita campos y aplica filtros por fecha para aprovechar la **partición**.

---

## 10) Evidencias obligatorias (capturas y tablas)

1. `ML.TRAINING_INFO` de ambos modelos.
2. Tablas `eval_*` con métricas.
3. Tabla `pred_*` con columnas `tipped_real`, `tipped_pred`, `p_yes`.
4. **Job Information** mostrando bytes procesados y región US.
5. Enlace al tablero con comparativas real vs. predicho.

---

## 11) Integración opcional (apoyo): Google Colab, scikit‑learn y PySpark

> **Recordatorio**: esto es **complementario**. La calificación exige que el modelado principal sea en **BQML**.

### 11.1 Colab + BigQuery + scikit‑learn (muestra)

```python
# %% Colab: autenticación y carga desde BigQuery
from google.colab import auth
auth.authenticate_user()

project_id = "ss2-bigquery-team0"

# Instalar librerías necesarias
!pip -q install google-cloud-bigquery pandas-gbq scikit-learn

import pandas as pd
from pandas_gbq import read_gbq

QUERY = """
SELECT
  tipped,
  hour_of_day, dow, month,
  trip_distance, total_amount, fare_amount, passenger_count
FROM `ss2-bigquery-team0.fase2_dataset.v_features_train`
LIMIT 200_000
"""

df_train = read_gbq(QUERY, project_id=project_id)

from sklearn.model_selection import train_test_split
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.metrics import roc_auc_score

X = df_train.drop(columns=["tipped"])
y = df_train["tipped"]

X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=42)

clf = GradientBoostingClassifier()
clf.fit(X_tr, y_tr)

pred = clf.predict_proba(X_te)[:,1]
print("AUC:", roc_auc_score(y_te, pred))
```

> **TODO del estudiante:** comparar la AUC de scikit‑learn vs. BQML y discutir posibles causas de diferencia.

### 11.2 Colab + PySpark (local en Colab)

```python
# %% Inicializar Spark en Colab (local)
!pip -q install pyspark
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("ss2-fase2").getOrCreate()

# Cargar un CSV exportado previamente desde BigQuery (ej.: predicciones) a /content
# (o leer con the BigQuery Storage API si configuras conectores avanzados)

pdf = df_train  # reusar df de arriba como ejemplo
sdf = spark.createDataFrame(pdf)

# Pequeño pipeline con VectorAssembler + LogisticRegression (ejemplo)
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.classification import LogisticRegression
from pyspark.ml import Pipeline

features = ["hour_of_day","dow","month","trip_distance","total_amount","fare_amount","passenger_count"]
va = VectorAssembler(inputCols=features, outputCol="features")
logr = LogisticRegression(featuresCol="features", labelCol="tipped")

pipe = Pipeline(stages=[va, logr])
model = pipe.fit(sdf)
print(model.stages[-1].summary.areaUnderROC)
```

> **Sugerencia**: mantener tamaños **moderados** para Colab; usar BigQuery para volumen.

---