package soporte.dto;

import java.time.LocalDateTime;

public record SolicitudDto(Long id, String nombreCliente, String estado, LocalDateTime fechaUltimaGestion) {
}