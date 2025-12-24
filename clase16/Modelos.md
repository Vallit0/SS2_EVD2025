# Explicación Matemática de los Modelos Usados en BigQuery ML

## 1. Regresión Logística (Modelo A)

### Fundamento teórico

La regresión logística modela la probabilidad de que un evento ocurra (por ejemplo, recibir propina) en función de un conjunto de variables predictoras.

Probabilidad de la clase positiva (y = 1):

<img src="https://latex.codecogs.com/svg.image?P(y=1|x)=\frac{1}{1+e^{-z}},\quad z=\beta_0+\sum_{j=1}^{p}\beta_jx_j" />

El logaritmo de la razón de probabilidades (log-odds) es lineal respecto a las variables:

<img src="https://latex.codecogs.com/svg.image?\log\frac{P}{1-P}=z" />

### Función de pérdida (log-loss)

La función objetivo que se minimiza es la pérdida logística promedio:

<img src="https://latex.codecogs.com/svg.image?\mathcal{L}(\beta)=-\frac{1}{n}\sum_{i=1}^{n}[y_i\log(p_i)+(1-y_i)\log(1-p_i)]" />

donde <img src="https://latex.codecogs.com/svg.image?p_i=\sigma(\beta_0+\beta^Tx_i)" />.

### Regularización

BigQuery ML permite usar regularización L1 y L2:

<img src="https://latex.codecogs.com/svg.image?\mathcal{J}(\beta)=\mathcal{L}(\beta)+\lambda_1\|\beta\|_1+\lambda_2\|\beta\|_2^2" />

* **L1 (Lasso):** promueve esparsidad en los coeficientes.
* **L2 (Ridge):** reduce la varianza del modelo y previene sobreajuste.

### Optimización

El modelo se entrena usando métodos de gradiente o Newton-Raphson, actualizando los coeficientes hasta minimizar la pérdida:

<img src="https://latex.codecogs.com/svg.image?\nabla\mathcal{L}=\frac{1}{n}\sum_{i=1}^{n}(p_i-y_i)x_i" />

### Interpretación

* Cada coeficiente ( \beta_j ) representa el cambio logarítmico en la razón de probabilidades al variar ( x_j ).
* Modelo lineal, interpretable y eficiente en datos estructurados.

---

## 2. Árbol Potenciado (Boosted Tree Classifier, Modelo B)

### Fundamento teórico

El modelo de árboles potenciados combina múltiples árboles de decisión débiles en una suma ponderada:

<img src="https://latex.codecogs.com/svg.image?F_M(x)=\sum_{m=1}^{M}\nu h_m(x)" />

donde cada (h_m) es un árbol de decisión y (\nu) la tasa de aprendizaje.

### Entrenamiento secuencial

1. Se calculan los **residuos** (gradientes del error actual).
2. Se entrena un árbol para predecir esos residuos.
3. Se actualiza el modelo:

<img src="https://latex.codecogs.com/svg.image?F_m(x)=F_{m-1}(x)+\nu h_m(x)" />

### Función de pérdida

Usa la misma pérdida logística que la regresión logística:

<img src="https://latex.codecogs.com/svg.image?\mathcal{L}(F)=-\frac{1}{n}\sum_{i=1}^{n}[y_i\log(p_i)+(1-y_i)\log(1-p_i)],\quad p_i=\sigma(F(x_i))" />

### Hiperparámetros clave

* **MAX_TREE_DEPTH:** profundidad máxima de cada árbol.
* **SUBSAMPLE:** porcentaje de datos usados por árbol (controla sobreajuste).
* **LEARN_RATE ((\nu))**: controla cuánto aporta cada árbol.
* **MIN_TREE_CHILD_WEIGHT:** tamaño mínimo de hoja.
* **NUM_PARALLEL_TREE:** número de árboles entrenados simultáneamente.

### Propiedades

* Captura **relaciones no lineales** e **interacciones** entre variables.
* Más potente que la regresión logística pero menos interpretable.
* Puede requerir calibración adicional para ajustar sus probabilidades.

### Predicción

El modelo final devuelve una probabilidad:

<img src="https://latex.codecogs.com/svg.image?P(y=1|x)=\sigma(F_M(x))=\frac{1}{1+e^{-F_M(x)}}" />

La clase predicha se obtiene aplicando un umbral (generalmente 0.5).

---

## 3. Comparación entre ambos modelos

| Característica                 | Regresión Logística | Boosted Tree                               |
| ------------------------------ | ------------------- | ------------------------------------------ |
| Tipo de frontera               | Lineal en log-odds  | No lineal y jerárquica                     |
| Interpretabilidad              | Alta                | Media-baja                                 |
| Calibración                    | Buena por defecto   | Puede requerir ajuste                      |
| Complejidad                    | Baja                | Alta                                       |
| Rendimiento en datos complejos | Limitado            | Muy alto                                   |
| Regularización                 | L1/L2               | Profundidad, tasa de aprendizaje, muestreo |

---

## 4. Conclusión

Ambos modelos cumplen propósitos complementarios:

* **Regresión Logística:** base interpretable y calibrada, útil para análisis explicativos.
* **Boosted Tree:** modelo más potente y flexible, ideal para clasificación con estructuras de datos complejas.

La combinación de ambos permite comparar linealidad frente a no linealidad y validar la consistencia de las probabilidades generadas.
