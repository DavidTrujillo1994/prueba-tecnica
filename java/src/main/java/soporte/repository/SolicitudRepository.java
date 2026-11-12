package soporte.repository;

import java.util.Optional;

import soporte.model.Solicitud;

// Solo para poder compilar y probar: en la aplicación real es el repositorio de Spring.
public interface SolicitudRepository {

    Optional<Solicitud> findById(Long id);
}