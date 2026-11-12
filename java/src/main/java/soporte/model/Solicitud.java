package soporte.model;

public class Solicitud {

    private final Long id;
    private final String estado;
    private final Cliente cliente;

    public Solicitud(Long id, String estado, Cliente cliente) {
        this.id = id;
        this.estado = estado;
        this.cliente = cliente;
    }

    public Long getId() {
        return id;
    }

    public String getEstado() {
        return estado;
    }

    public Cliente getCliente() {
        return cliente;
    }
}