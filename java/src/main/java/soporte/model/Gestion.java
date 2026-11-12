package soporte.model;

import java.time.LocalDateTime;

public class Gestion {

    private final LocalDateTime fechaGestion;

    public Gestion(LocalDateTime fechaGestion) {
        this.fechaGestion = fechaGestion;
    }

    public LocalDateTime getFechaGestion() {
        return fechaGestion;
    }
}
