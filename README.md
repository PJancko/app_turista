/lib
 ┣ main.dart                   ← Punto de entrada
 ┣ /screens                    ← Todas las pantallas principales (UI completas)
 ┃ ┣ login_screen.dart
 ┃ ┣ home_screen.dart
 ┃ ┣ map_screen.dart
 ┃ ┣ eventos_tab.dart
 ┃ ┣ lugares_tab.dart
 ┃ ┗ favoritos_tab.dart
 ┣ /widgets                    ← Componentes reutilizables (footer, cards, botones, etc.)
 ┃ ┣ app_footer.dart
 ┃ ┣ evento_card.dart
 ┃ ┣ lugar_card.dart
 ┣ /services                   ← Comunicación con Firebase, API, geolocalización, etc.
 ┃ ┣ auth_service.dart
 ┃ ┣ firestore_service.dart
 ┃ ┗ location_service.dart
 ┣ /models                     ← Clases de datos: Evento, Lugar, Usuario, etc.
 ┃ ┣ evento.dart
 ┃ ┣ lugar.dart
 ┃ ┣ usuario.dart
 ┣ /utils                      ← Funciones de utilidad y lógica de recomendación
 ┃ ┣ recomendador.dart
 ┣ /themes                     ← Colores, estilos, tipografías
 ┃ ┣ app_colors.dart
 ┃ ┣ app_text_styles.dart
 ┣ /config                     ← Configuración global, rutas, constantes
 ┃ ┣ app_routes.dart
 ┃ ┗ constants.dart
