package soporte.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import soporte.dto.SolicitudDto;
import soporte.exception.SolicitudNoEncontradaException;
import soporte.model.Cliente;
import soporte.model.Gestion;
import soporte.model.Solicitud;
import soporte.repository.GestionRepository;
import soporte.repository.SolicitudRepository;

@ExtendWith(MockitoExtension.class)
class SolicitudServiceTest {

    private static final Long ID = 781245L;

    @Mock
    private SolicitudRepository repository;

    @Mock
    private GestionRepository gestionRepository;

    @InjectMocks
    private SolicitudService service;

    // ---------- Escenarios pedidos por la prueba ----------

    @Test
    void solicitudExistenteConGestiones_devuelveSusDatos() {
        LocalDateTime fecha = LocalDateTime.of(2026, 11, 5, 15, 30);
        when(repository.findById(ID))
                .thenReturn(Optional.of(new Solicitud(ID, "PENDIENTE", new Cliente("  Ana Pérez  "))));
        when(gestionRepository.findBySolicitudId(ID))
                .thenReturn(List.of(new Gestion(fecha)));

        SolicitudDto dto = service.consultar(ID);

        assertEquals(ID, dto.id());
        assertEquals("Ana Pérez", dto.nombreCliente());
        assertEquals("PENDIENTE", dto.estado());
        assertEquals(fecha, dto.fechaUltimaGestion());
    }

    @Test
    void solicitudInexistente_lanzaExcepcionClaraConElId() {
        when(repository.findById(ID)).thenReturn(Optional.empty());

        SolicitudNoEncontradaException e =
                assertThrows(SolicitudNoEncontradaException.class, () -> service.consultar(ID));

        assertTrue(e.getMessage().contains("id=781245"));
        verifyNoInteractions(gestionRepository);
    }

    @Test
    void solicitudSinGestiones_devuelveFechaNulaSinFallar() {
        when(repository.findById(ID))
                .thenReturn(Optional.of(new Solicitud(ID, "PENDIENTE", new Cliente("Ana Pérez"))));
        when(gestionRepository.findBySolicitudId(ID)).thenReturn(List.of());

        SolicitudDto dto = service.consultar(ID);

        assertEquals("Ana Pérez", dto.nombreCliente());
        assertNull(dto.fechaUltimaGestion());
    }

    // ---------- Casos de borde ----------

    @Test
    void solicitudSinCliente_devuelveNombreNuloSinFallar() {
        when(repository.findById(ID)).thenReturn(Optional.of(new Solicitud(ID, "PENDIENTE", null)));
        when(gestionRepository.findBySolicitudId(ID)).thenReturn(List.of());

        assertNull(service.consultar(ID).nombreCliente());
    }

    @Test
    void clienteSinNombre_devuelveNombreNuloSinFallar() {
        when(repository.findById(ID))
                .thenReturn(Optional.of(new Solicitud(ID, "PENDIENTE", new Cliente(null))));
        when(gestionRepository.findBySolicitudId(ID)).thenReturn(List.of());

        assertNull(service.consultar(ID).nombreCliente());
    }

    // ---------- Reproducción del incidente con el método ORIGINAL ----------

    @Test
    void original_solicitudInexistente_lanzaNullPointerException() {
        SolicitudServiceOriginal original = new SolicitudServiceOriginal(repository, gestionRepository);
        when(repository.findById(ID)).thenReturn(Optional.empty());

        assertThrows(NullPointerException.class, () -> original.consultar(ID));
    }

    @Test
    void original_solicitudSinGestiones_lanzaIndexOutOfBounds() {
        SolicitudServiceOriginal original = new SolicitudServiceOriginal(repository, gestionRepository);
        when(repository.findById(ID))
                .thenReturn(Optional.of(new Solicitud(ID, "PENDIENTE", new Cliente("Ana Pérez"))));
        when(gestionRepository.findBySolicitudId(ID)).thenReturn(List.of());

        assertThrows(IndexOutOfBoundsException.class, () -> original.consultar(ID));
    }
}