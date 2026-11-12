package soporte.service;

import java.util.List;

import soporte.dto.SolicitudDto;
import soporte.model.Gestion;
import soporte.model.Solicitud;
import soporte.repository.GestionRepository;
import soporte.repository.SolicitudRepository;

// El método ORIGINAL de la prueba, tal cual, solo para poder reproducir el error.
public class SolicitudServiceOriginal {

    private final SolicitudRepository repository;
    private final GestionRepository gestionRepository;

    public SolicitudServiceOriginal(SolicitudRepository repository, GestionRepository gestionRepository) {
        this.repository = repository;
        this.gestionRepository = gestionRepository;
    }

    public SolicitudDto consultar(Long id) {
        Solicitud solicitud = repository.findById(id).orElse(null);
        String nombreCliente = solicitud.getCliente().getNombre().trim();
        List<Gestion> gestiones = gestionRepository.findBySolicitudId(id);
        Gestion ultima = gestiones.get(0);
        return new SolicitudDto(
                solicitud.getId(),
                nombreCliente,
                solicitud.getEstado(),
                ultima.getFechaGestion()
        );
    }
}