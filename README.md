Instalación y Ejecución
Sigue estos pasos para clonar, instalar dependencias y ejecutar la aplicación localmente en tu dispositivo o emulador:

1. Clonar el repositorio
git clone https://github.com/tu-usuario/tu-repo.git
cd tu-repo

2. Instalar dependencias
flutter pub get

3. Configurar Firebase
Crea un proyecto en Firebase Console.
Activa Authentication con Email/Password.
Crea una base de datos Firestore con las siguientes colecciones:
usuarios, eventos, lugares, calificaciones, calificaciones_lugares.
Descarga el archivo google-services.json desde Firebase.
Colócalo en:
android/app/google-services.json

4. Ejecutar la app
Conecta un emulador o un dispositivo físico y ejecuta:
flutter run