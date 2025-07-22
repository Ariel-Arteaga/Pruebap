class Estudiante:
    def __init__(self, nombre, ci, correo, telefono, edad):
        self.nombre = nombre
        self.ci = ci
        self.correo = correo
        self.telefono = telefono
        self.edad = edad
        self.siguiente = None

class Inscrito:
    def __init__(self, fecha_inscripcion, ci_estudiante):
        self.fecha_inscripcion = fecha_inscripcion
        self.ci_estudiante = ci_estudiante
        self.anterior = None
        self.siguiente = None

class Paralelo:
    def __init__(self, docente, identificador):
        self.docente = docente
        self.identificador = identificador
        self.inscritos = None  # Doble normal
        self.siguiente = self  # Simple circular

    def contar_inscritos(self):
        count = 0
        actual = self.inscritos
        while actual:
            count += 1
            actual = actual.siguiente
        return count

class Materia:
    def __init__(self, sigla, nombre):
        self.sigla = sigla
        self.nombre = nombre
        self.paralelos = None  # Simple circular
        self.anterior = self
        self.siguiente = self

class Sistema:
    def __init__(self):
        self.estudiantes = None  # Simple
        self.materias = None     # Doble circular

    # --- Gestión de estudiantes ---
    def agregar_estudiante(self, nombre, ci, correo, telefono, edad):
        nuevo = Estudiante(nombre, ci, correo, telefono, edad)
        nuevo.siguiente = self.estudiantes
        self.estudiantes = nuevo

    def buscar_estudiante(self, ci):
        actual = self.estudiantes
        while actual:
            if actual.ci == ci:
                return actual
            actual = actual.siguiente
        return None

    def mostrar_estudiantes(self):
        print("=== Estudiantes ===")
        actual = self.estudiantes
        while actual:
            print(f"Nombre: {actual.nombre}, CI: {actual.ci}, Correo: {actual.correo}, Teléfono: {actual.telefono}, Edad: {actual.edad}")
            actual = actual.siguiente

    # --- Gestión de materias ---
    def agregar_materia(self, sigla, nombre):
        nueva = Materia(sigla, nombre)
        if not self.materias:
            self.materias = nueva
        else:
            ult = self.materias.anterior
            ult.siguiente = nueva
            nueva.anterior = ult
            nueva.siguiente = self.materias
            self.materias.anterior = nueva

    def buscar_materia(self, sigla):
        actual = self.materias
        if not actual:
            return None
        inicio = actual
        while True:
            if actual.sigla == sigla:
                return actual
            actual = actual.siguiente
            if actual == inicio:
                break
        return None

    def mostrar_materias(self):
        print("=== Materias ===")
        materia = self.materias
        if not materia:
            print("No hay materias.")
            return
        inicio = materia
        while True:
            print(f"Sigla: {materia.sigla}, Nombre: {materia.nombre}")
            self.mostrar_paralelos(materia)
            materia = materia.siguiente
            if materia == inicio:
                break

    # --- Gestión de paralelos ---
    def agregar_paralelo(self, sigla, docente, identificador):
        materia = self.buscar_materia(sigla)
        if not materia:
            return
        nuevo = Paralelo(docente, identificador)
        if not materia.paralelos:
            materia.paralelos = nuevo
        else:
            ult = materia.paralelos
            while ult.siguiente != materia.paralelos:
                ult = ult.siguiente
            ult.siguiente = nuevo
            nuevo.siguiente = materia.paralelos

    def buscar_paralelo(self, materia, identificador):
        paralelo = materia.paralelos
        if not paralelo:
            return None
        inicio = paralelo
        while True:
            if paralelo.identificador == identificador:
                return paralelo
            paralelo = paralelo.siguiente
            if paralelo == inicio:
                break
        return None

    def mostrar_paralelos(self, materia):
        paralelo = materia.paralelos
        if not paralelo:
            print("  No hay paralelos.")
            return
        print("  Paralelos:")
        inicio = paralelo
        while True:
            print(f"    Paralelo: {paralelo.identificador}, Docente: {paralelo.docente}, Inscritos: {paralelo.contar_inscritos()}")
            self.mostrar_inscritos(paralelo)
            paralelo = paralelo.siguiente
            if paralelo == inicio:
                break

    # --- Inscribir estudiante ---
    def inscribir_estudiante(self, sigla, paralelo_id, ci, fecha):
        materia = self.buscar_materia(sigla)
        if not materia:
            return
        paralelo = self.buscar_paralelo(materia, paralelo_id)
        if not paralelo:
            return
        nuevo = Inscrito(fecha, ci)
        if not paralelo.inscritos:
            paralelo.inscritos = nuevo
        else:
            actual = paralelo.inscritos
            while actual.siguiente:
                actual = actual.siguiente
            actual.siguiente = nuevo
            nuevo.anterior = actual

    def mostrar_inscritos(self, paralelo):
        actual = paralelo.inscritos
        if not actual:
            print("      No hay inscritos.")
            return
        print("      Inscritos:")
        while actual:
            print(f"        CI: {actual.ci_estudiante}, Fecha: {actual.fecha_inscripcion}")
            actual = actual.siguiente

    # --- 1. Búsqueda por CI ---
    def buscar_materias_por_ci_final(self, digito_final):
        resultado = set()
        materia = self.materias
        if not materia:
            return []
        inicio = materia
        while True:
            paralelo = materia.paralelos
            if paralelo:
                p_inicio = paralelo
                while True:
                    inscrito = paralelo.inscritos
                    while inscrito:
                        if str(inscrito.ci_estudiante).endswith(str(digito_final)):
                            resultado.add(materia.sigla)
                            break
                        inscrito = inscrito.siguiente
                    paralelo = paralelo.siguiente
                    if paralelo == p_inicio:
                        break
            materia = materia.siguiente
            if materia == inicio:
                break
        return list(resultado)

    # --- 2. Gestión de Paralelos ---
    def agregar_paralelo_y_mover_estudiantes(self, sigla, docente, nuevo_id, digito_final):
        materia = self.buscar_materia(sigla)
        if not materia:
            return
        self.agregar_paralelo(sigla, docente, nuevo_id)
        nuevo_paralelo = self.buscar_paralelo(materia, nuevo_id)
        paralelos = []
        paralelo = materia.paralelos
        if not paralelo:
            return
        p_inicio = paralelo
        while True:
            if paralelo.identificador != nuevo_id:
                paralelos.append(paralelo)
            paralelo = paralelo.siguiente
            if paralelo == p_inicio:
                break
        for paralelo in paralelos:
            actual = paralelo.inscritos
            while actual:
                siguiente = actual.siguiente
                if str(actual.ci_estudiante).endswith(str(digito_final)):
                    # Remover de este paralelo
                    if actual.anterior:
                        actual.anterior.siguiente = actual.siguiente
                    if actual.siguiente:
                        actual.siguiente.anterior = actual.anterior
                    if actual == paralelo.inscritos:
                        paralelo.inscritos = actual.siguiente
                    # Insertar al nuevo paralelo
                    actual.anterior = None
                    actual.siguiente = None
                    if not nuevo_paralelo.inscritos:
                        nuevo_paralelo.inscritos = actual
                    else:
                        ins = nuevo_paralelo.inscritos
                        while ins.siguiente:
                            ins = ins.siguiente
                        ins.siguiente = actual
                        actual.anterior = ins
                actual = siguiente

    # --- 3. Reorganización de Paralelos ---
    def eliminar_paralelo_y_mover_inscritos(self, sigla, paralelo_id):
        materia = self.buscar_materia(sigla)
        if not materia:
            return
        paralelo = self.buscar_paralelo(materia, paralelo_id)
        if not paralelo:
            return
        # Buscar paralelo con menos inscritos (que no sea el que se elimina)
        min_paralelo = None
        min_count = float('inf')
        p = materia.paralelos
        p_inicio = p
        while True:
            if p.identificador != paralelo_id:
                count = p.contar_inscritos()
                if count < min_count:
                    min_count = count
                    min_paralelo = p
            p = p.siguiente
            if p == p_inicio:
                break
        # Mover inscritos
        actual = paralelo.inscritos
        while actual:
            siguiente = actual.siguiente
            actual.anterior = None
            actual.siguiente = None
            if not min_paralelo.inscritos:
                min_paralelo.inscritos = actual
            else:
                ins = min_paralelo.inscritos
                while ins.siguiente:
                    ins = ins.siguiente
                ins.siguiente = actual
                actual.anterior = ins
            actual = siguiente
        # Eliminar el paralelo de la lista circular
        prev = materia.paralelos
        if prev == paralelo:
            # Solo hay uno
            materia.paralelos = paralelo.siguiente if paralelo.siguiente != paralelo else None
        else:
            while prev.siguiente != paralelo:
                prev = prev.siguiente
            prev.siguiente = paralelo.siguiente
            if materia.paralelos == paralelo:
                materia.paralelos = paralelo.siguiente

    # --- 4. Cierre de Materias ---
    def cerrar_materia(self, sigla):
        materia = self.buscar_materia(sigla)
        if not materia:
            return []
        afectados = []
        paralelo = materia.paralelos
        if paralelo:
            p_inicio = paralelo
            while True:
                inscrito = paralelo.inscritos
                while inscrito:
                    est = self.buscar_estudiante(inscrito.ci_estudiante)
                    if est:
                        afectados.append((est.nombre, est.correo, est.telefono))
                    inscrito = inscrito.siguiente
                paralelo = paralelo.siguiente
                if paralelo == p_inicio:
                    break
        # Eliminar materia de la lista doble circular
        if materia.siguiente == materia:
            self.materias = None
        else:
            materia.anterior.siguiente = materia.siguiente
            materia.siguiente.anterior = materia.anterior
            if self.materias == materia:
                self.materias = materia.siguiente
        return afectados

    # --- 5. Consultas: materias inscritas por estudiante ---
    def materias_por_estudiante(self, ci):
        resultado = []
        materia = self.materias
        if not materia:
            return []
        inicio = materia
        while True:
            paralelo = materia.paralelos
            if paralelo:
                p_inicio = paralelo
                while True:
                    inscrito = paralelo.inscritos
                    while inscrito:
                        if inscrito.ci_estudiante == ci:
                            resultado.append(materia.sigla)
                            break
                        inscrito = inscrito.siguiente
                    paralelo = paralelo.siguiente
                    if paralelo == p_inicio:
                        break
            materia = materia.siguiente
            if materia == inicio:
                break
        return resultado

    # --- 6. Gestión de Capacidad ---
    def gestionar_capacidad(self, sigla, paralelo_id, limite):
        materia = self.buscar_materia(sigla)
        if not materia:
            return
        paralelo = self.buscar_paralelo(materia, paralelo_id)
        if not paralelo:
            return
        total = paralelo.contar_inscritos()
        if total > limite:
            nuevo_id = paralelo_id + "_extra"
            self.agregar_paralelo(sigla, paralelo.docente, nuevo_id)
            nuevo_paralelo = self.buscar_paralelo(materia, nuevo_id)
            # Mover la mitad de los estudiantes
            mitad = total // 2
            actual = paralelo.inscritos
            count = 0
            while actual and count < mitad:
                siguiente = actual.siguiente
                # Remover de este paralelo
                if actual.anterior:
                    actual.anterior.siguiente = actual.siguiente
                if actual.siguiente:
                    actual.siguiente.anterior = actual.anterior
                if actual == paralelo.inscritos:
                    paralelo.inscritos = actual.siguiente
                # Insertar al nuevo paralelo
                actual.anterior = None
                actual.siguiente = None
                if not nuevo_paralelo.inscritos:
                    nuevo_paralelo.inscritos = actual
                else:
                    ins = nuevo_paralelo.inscritos
                    while ins.siguiente:
                        ins = ins.siguiente
                    ins.siguiente = actual
                    actual.anterior = ins
                actual = siguiente
                count += 1

# --- Ejemplo de uso y demostración de TODAS las operaciones ---
if __name__ == "__main__":
    sistema = Sistema()
    # Agregar estudiantes
    sistema.agregar_estudiante("Ana", "12345", "ana@mail.com", "777-111", 20)
    sistema.agregar_estudiante("Luis", "23456", "luis@mail.com", "777-222", 21)
    sistema.agregar_estudiante("Maria", "34567", "maria@mail.com", "777-333", 22)
    sistema.agregar_estudiante("Pedro", "45675", "pedro@mail.com", "777-444", 23)
    sistema.agregar_estudiante("Sofia", "56785", "sofia@mail.com", "777-555", 24)

    # Agregar materia y paralelos
    sistema.agregar_materia("INF101", "Programación")
    sistema.agregar_paralelo("INF101", "Prof. Perez", "A")
    sistema.agregar_paralelo("INF101", "Prof. Gomez", "B")

    # Inscribir estudiantes
    sistema.inscribir_estudiante("INF101", "A", "12345", "2024-01-10")
    sistema.inscribir_estudiante("INF101", "A", "23456", "2024-01-11")
    sistema.inscribir_estudiante("INF101", "A", "34567", "2024-01-12")
    sistema.inscribir_estudiante("INF101", "B", "45675", "2024-01-13")
    sistema.inscribir_estudiante("INF101", "B", "56785", "2024-01-14")

    # Mostrar todos los datos
    print("\n--- DATOS INICIALES ---")
    sistema.mostrar_estudiantes()
    sistema.mostrar_materias()

    # 1. Búsqueda por CI
    print("\n--- 1. Materias con estudiantes cuyo CI termina en 5 ---")
    print(sistema.buscar_materias_por_ci_final(5))

    # 2. Gestión de Paralelos: agregar paralelo y mover estudiantes cuyo CI termina en 5
    print("\n--- 2. Agregar paralelo 'C' y mover estudiantes cuyo CI termina en 5 ---")
    sistema.agregar_paralelo_y_mover_estudiantes("INF101", "Prof. Lopez", "C", 5)
    sistema.mostrar_materias()

    # 3. Reorganización de Paralelos: eliminar paralelo B y mover sus inscritos
    print("\n--- 3. Eliminar paralelo 'B' y mover sus inscritos al paralelo con menos inscritos ---")
    sistema.eliminar_paralelo_y_mover_inscritos("INF101", "B")
    sistema.mostrar_materias()

    # 4. Cierre de Materias: cerrar INF101 y mostrar afectados
    print("\n--- 4. Cierre de materia 'INF101' (afectados) ---")
    afectados = sistema.cerrar_materia("INF101")
    for nombre, correo, tel in afectados:
        print(f"Nombre: {nombre}, Correo: {correo}, Teléfono: {tel}")

    # 5. Consultas: materias inscritas por estudiante
    print("\n--- 5. Materias inscritas por cada estudiante ---")
    actual = sistema.estudiantes
    while actual:
        materias = sistema.materias_por_estudiante(actual.ci)
        print(f"{actual.nombre} ({actual.ci}): {materias}")
        actual = actual.siguiente

    # 6. Gestión de Capacidad: saturar un paralelo y dividir inscritos
    print("\n--- 6. Gestión de capacidad (paralelo saturado) ---")
    # Volver a crear la materia y paralelos para este ejemplo
    sistema.agregar_materia("INF102", "Estructuras")
    sistema.agregar_paralelo("INF102", "Prof. Ruiz", "A")
    # Inscribir muchos estudiantes en el mismo paralelo
    sistema.inscribir_estudiante("INF102", "A", "12345", "2024-02-01")
    sistema.inscribir_estudiante("INF102", "A", "23456", "2024-02-02")
    sistema.inscribir_estudiante("INF102", "A", "34567", "2024-02-03")
    sistema.inscribir_estudiante("INF102", "A", "45675", "2024-02-04")
    sistema.inscribir_estudiante("INF102", "A", "56785", "2024-02-05")
    sistema.mostrar_materias()
    print("Aplicando gestión de capacidad (límite 3)...")
    sistema.gestionar_capacidad("INF102", "A", 3)
    sistema.mostrar_materias()
w
