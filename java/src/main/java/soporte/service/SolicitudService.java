package soporte.service;

import java.time.LocalDateTime;
import java.util.List;

import soporte.dto.SolicitudDto;
import soporte.exception.SolicitudNoEncontradaException;
import soporte.model.Cliente;
import soporte.model.Gestion;
import soporte.model.Solicitud;
import soporte.repository.GestionRepository;
import soporte.repository.SolicitudRepository;

public class SolicitudService {

    private final SolicitudRepository repository;
    private final GestionRepository gestionRepository;

    public SolicitudService(SolicitudRepository repository, GestionRepository gestionRepository) {
        this.repository = repository;
        this.gestionRepository = gestionRepository;
    }

    public SolicitudDto consultar(Long id) {
        Solicitud solicitud = repository.findById(id)
                .orElseThrow(() -> new SolicitudNoEncontradaException(id));

        Cliente cliente = solicitud.getCliente();
        String nombreCliente = (cliente != null && cliente.getNombre() != null)
                ? cliente.getNombre().trim() : null;

        List<Gestion> gestiones = gestionRepository.findBySolicitudId(id);
        LocalDateTime fecha = gestiones.isEmpty() ? null : gestiones.get(0).getFechaGestion();

        return new SolicitudDto(solicitud.getId(), nombreCliente, solicitud.getEstado(), fecha);
    }
}