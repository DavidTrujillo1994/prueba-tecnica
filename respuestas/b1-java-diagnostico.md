B1. Lectura de código y diagnóstico
9. Explique qué hace el método y por qué puede fallar.

El método busca una solicitud por su id, saca el nombre del cliente y le quita los espacios, trae las gestiones de esa solicitud, toma la primera como si fuera la última y devuelve un SolicitudDto con esos datos.

Lo que falla es el orElse(null). findById devuelve un Optional, y si el id no existe viene vacío, pero el código lo convierte en null. Entonces en la línea siguiente se llama a solicitud.getCliente() sobre un null y sale el NullPointerException. El log lo dice claro: "solicitud" is null. Con el id 781245 lo más probable es que esa solicitud simplemente no exista en la base.

Lo otro que molesta es que el controlador responde un 500 genérico. Un id que no existe no es un error del servidor, y así soporte no puede distinguir una cosa de la otra.

10. Identifique al menos tres situaciones problemáticas o frágiles en el fragmento.

- El orElse(null): pierde lo bueno del Optional y pasa el problema a la línea siguiente. Es la causa del error del log.
- La cadena solicitud.getCliente().getNombre().trim(): cualquiera de las tres partes puede ser null (una solicitud sin cliente, un cliente sin nombre) y el error no diría cuál fue.
- El gestiones.get(0): si la solicitud no tiene gestiones, la lista viene vacía y lanza un IndexOutOfBoundsException. Una solicitud nueva sin gestiones es algo normal, no debería romper.
- Se asume que la primera de la lista es la última gestión, pero findBySolicitudId no garantiza ningún orden. La variable se llama ultima y el código no asegura que lo sea.

11. Proponga una corrección mínima y mantenible. Puede entregar el método corregido o un diff/pseudodiff claro.
java/src/main/java/soporte/SolicitudService.java