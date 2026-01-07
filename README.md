# 💸 CompartimosGastos

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

> **Proyecto Final de Ciclo (DAM) - Campus Digital** > Una solución multiplataforma para acabar con los conflictos financieros en grupos de amigos, viajes y compañeros de piso.

---

## 📱 Descripción

**CompartimosGastos** es una aplicación diseñada para centralizar y simplificar la economía de grupo. Olvídate de las hojas de cálculo y las notas dispersas; esta app permite crear grupos, registrar gastos y, lo más importante, **calcular automáticamente quién debe a quién** para saldar las deudas de la forma más eficiente posible.

Desarrollada con **Flutter** y respaldada por **Firebase**.

### ✨ Funcionalidades Principales

* **👥 Gestión de Grupos:** Creación personalizada de grupos (nombre, color) e invitación de miembros mediante código único.
* **🔄 Sincronización en Tiempo Real:** Gracias a Firestore, si un usuario añade un gasto, aparece instantáneamente en los dispositivos de los demás.
* **💰 Algoritmo de Reparto Justo:** Sistema propio de redondeo que gestiona los decimales periódicos para que nunca se pierda ni un céntimo en el total.
* **📊 Balances Dinámicos:** Visualización clara de deudas ("Tú debes", "Te deben") y liquidación de saldos.
* **📝 Listas Colaborativas:** Planificación de compras futuras (supermercado, entradas, etc.) compartida por todo el grupo.
* **🕵️ Modo Invitado:** Permite acceder y participar en grupos sin necesidad de un registro completo por email.

---

## 🛠️ Stack Tecnológico

El proyecto sigue una arquitectura **MVC (Modelo-Vista-Controlador)** para garantizar la escalabilidad y el mantenimiento del código.

* **Frontend:** [Flutter](https://flutter.dev/) (Dart) - Diseño Responsive y Material Design 3.
* **Backend:** [Firebase](https://firebase.google.com/) (Google Cloud).
    * **Authentication:** Gestión de sesiones y usuarios anónimos.
    * **Cloud Firestore:** Base de datos NoSQL orientada a documentos.
* **Herramientas:** Git, GitHub, Android Studio, Visual Studio Code.

---

## 🚀 Probar la Aplicación

Tienes dos formas de probar el proyecto:

### 1. 🌐 Versión Web
Puedes acceder a la versión desplegada en GitHub Pages sin instalar nada:
👉 **[Abrir CompartimosGastos Web](https://joseroyo3.github.io/)**

### 2. 🤖 Android (APK)
Descarga la última versión compilada (`.apk`) desde este repositorio e instálala en tu dispositivo Android:
👉 **[Descargar APK (Release)](https://github.com/joseroyo3/compartimos_gastos_app/blob/master/compartimos_gastos.apk)**

---

## 🏗️ Instalación para Desarrolladores

Si quieres clonar y ejecutar este proyecto en tu entorno local:

1.  **Clonar el repositorio:**
    ```bash
    git clone [https://github.com/joseroyo3/compartimos_gastos_app.git](https://github.com/joseroyo3/compartimos_gastos_app.git)
    ```
2.  **Instalar dependencias:**
    ```bash
    cd compartimos_gastos_app
    flutter pub get
    ```
3.  **Configurar Firebase:**
    * Necesitarás tu propio archivo `google-services.json` (Android) y `firebase_options.dart`.
    * Usa `flutterfire configure` para vincular tu propio proyecto.
4.  **Ejecutar:**
    ```bash
    flutter run
    ```

---

## 👨‍💻 Autor

**Jose Royo Andreu** Desarrollador Multiplataforma (DAM)  
[GitHub Profile](https://github.com/joseroyo3)

---
