package soporte.exception;

// En el servicio real se podría anotar con @ResponseStatus(HttpStatus.NOT_FOUND)
// para que el controlador responda 404 en lugar de 500.
public class SolicitudNoEncontradaException extends RuntimeException {

    public SolicitudNoEncontradaException(Long id) {
        super("Solicitud no encontrada. id=" + id);
    }
}
