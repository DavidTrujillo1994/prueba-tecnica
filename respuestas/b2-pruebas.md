B2. Verificación de la corrección
Proponga pruebas automatizadas o casos verificables para demostrar que su cambio Java corrige el
incidente sin romper escenarios normales. Incluya como mínimo: solicitud existente con gestiones,
solicitud inexistente y solicitud sin gestiones. Si identifica otro caso de borde relevante, inclúyalo.

Código java: java/src/test/java/soporte/service/SolicitudServiceTest.java

Las pruebas las hice con Junit5 y Mockito; los repositorios los simulo con Mockito, así que no necesito Spring ni una bd, pruebo solo la lógica del servicio.

- Solicitud existente con gestiones. Entrada: una solicitud con estado PENDIENTE, cliente "  Ana Pérez  " (con espacios) y una gestión con fecha. Esperado: devuelve el id, el nombre sin espacios ("Ana Pérez"), el estado y la fecha de la gestión. Demuestra que el caso normal sigue funcionando y que el trim se mantiene.
- Solicitud inexistente. Entrada: el repositorio devuelve vacío para el id 781245, el del log. Esperado: lanza SolicitudNoEncontradaException con el mensaje "id=781245", y no se consultan las gestiones. Demuestra que el incidente del log se corrigió: ya no hay un NullPointerException sino un error claro, y no se hace trabajo de más.
- Solicitud sin gestiones. Entrada: la solicitud existe pero la lista de gestiones viene vacía. Esperado: devuelve la solicitud con la fecha en null, sin lanzar excepción. Demuestra que un caso normal del negocio ya no rompe con un IndexOutOfBoundsException.
- Solicitud sin cliente (caso de borde). Entrada: la solicitud existe pero su cliente es null. Esperado: devuelve el nombre en null, sin fallar.
- Cliente sin nombre (caso de borde). Entrada: el cliente existe pero su nombre es null. Esperado: devuelve el nombre en null, sin fallar.

Logs pruebas: 
Ejecuté las pruebas con mvn test y pasaron las 7 de cuales 5 sobre el método corregido y 2 que reproducen el error del original, sin fallos.
PS C:\Users\aaa12\Downloads\Prueba tecnica> cd java
PS C:\Users\aaa12\Downloads\Prueba tecnica\java> mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] --------------------< soporte:gestion-solicitudes >---------------------
[INFO] Building gestion-solicitudes 1.0-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- resources:3.3.1:resources (default-resources) @ gestion-solicitudes ---
[INFO] skip non existing resourceDirectory C:\Users\aaa12\Downloads\Prueba tecnica\java\src\main\resources
[INFO] 
[INFO] --- compiler:3.13.0:compile (default-compile) @ gestion-solicitudes ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- resources:3.3.1:testResources (default-testResources) @ gestion-solicitudes ---
[INFO] skip non existing resourceDirectory C:\Users\aaa12\Downloads\Prueba tecnica\java\src\test\resources
[INFO] 
[INFO] --- compiler:3.13.0:testCompile (default-testCompile) @ gestion-solicitudes ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- surefire:3.2.5:test (default-test) @ gestion-solicitudes ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running soporte.service.SolicitudServiceTest
WARNING: A Java agent has been loaded dynamically (C:\Users\aaa12\.m2\repository\net\bytebuddy\byte-buddy-agent\1.14.12\byte-buddy-agent-1.14.12.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
Java HotSpot(TM) 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.385 s -- in soporte.service.SolicitudServiceTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  3.755 s
[INFO] Finished at: 2026-11-11T22:47:26-05:00
[INFO] -------------------------------------------------------
