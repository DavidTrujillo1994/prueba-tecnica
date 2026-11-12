package soporte.repository;

import java.util.List;

import soporte.model.Gestion;

// Solo para poder compilar y probar: en la aplicación real es el repositorio de Spring.
public interface GestionRepository {

    List<Gestion> findBySolicitudId(Long idSolicitud);
}