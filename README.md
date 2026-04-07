# \# DECAFIA App – Android

# 

# > Aplicación móvil para detección de enfermedades en hojas de café con IA offline.

# 

# \[!\[Flutter](https://img.shields.io/badge/Flutter-3.27.4-blue)](https://flutter.dev)

# \[!\[Android](https://img.shields.io/badge/Android-APK-green)](https://github.com/estebanr25/decafia-app/releases)

# 

# \## Características

# 

# \- Diagnóstico offline con modelo YOLOv8m (ONNX)

# \- Detecta Roya, Cochinilla y Minador de la hoja

# \- Historial de diagnósticos con SQLite

# \- Mapa de fincas con GPS y OpenStreetMap

# \- Biblioteca de enfermedades con info de Cenicafé

# \- Compartir resultados por WhatsApp

# 

# \## Descargar APK

# 

# 👉 \[Releases](https://github.com/estebanr25/decafia-app/releases)

# 

# \## Pantallas

# 

# | Inicio | Diagnóstico | Historial | Mapa |

# |--------|-------------|-----------|------|

# | \_screenshot\_ | \_screenshot\_ | \_screenshot\_ | \_screenshot\_ |

# 

# \## Requisitos para compilar

# 

# \- Flutter 3.27.4

# \- Android Studio con JBR Java

# \- Modelo `decafia\_best.onnx` en `assets/models/`

# &#x20; (descargar de \[Hugging Face](https://huggingface.co/estebanr25/decafia))

# 

# \## Instalación

# ```bash

# git clone https://github.com/estebanr25/decafia-app.git

# cd decafia-app

# \# Descargar modelo ONNX y poner en assets/models/

# flutter pub get

# flutter build apk --release

# ```

# 

# \## Modelo

# 

# Basado en YOLOv8m entrenado con 2,786 imágenes de campo real.

# Ver repositorio del modelo: \[decafia-model](https://github.com/estebanr25/decafia-model)

# 

# \## Licencia

# 

# MIT Licensefull API reference.

