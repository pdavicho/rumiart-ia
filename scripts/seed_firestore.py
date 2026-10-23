"""
Script para subir las 19 obras de arte a Firestore.
Corre con:
    python scripts/seed_firestore.py

Usa firebase-admin con Application Default Credentials (ADC).
Si no tienes ADC configurado, primero corre:
    pip install google-cloud-firestore
    gcloud auth application-default login
O descarga un Service Account JSON desde Firebase Console.
"""
import json
import os
import sys

# ── Datos de las 19 obras ─────────────────────────────────────────────────────
artworks = {
    # Sala 1 — Primeros Pobladores
    "sala1_0": {"salaId": "sala1", "classIndex": 0, "roomName": "Sala 1 - Primeros Pobladores", "nombre": "Olla Globular", "artista": "Cultura Cosanga", "descripcion": "Olla de barro precolombina de procedencia Cosanga, caracterizada por un cuerpo globular y un cuello corto. Presenta la forma típica de las piezas utilitarias de la región."},
    "sala1_1": {"salaId": "sala1", "classIndex": 1, "roomName": "Sala 1 - Primeros Pobladores", "nombre": "Plato Pentápodo", "artista": "Cultura Jama Coaque", "descripcion": "Recipiente ceremonial de cinco patas y con decoraciones particulares, utilizado para ofrendas y rituales."},
    "sala1_2": {"salaId": "sala1", "classIndex": 2, "roomName": "Sala 1 - Primeros Pobladores", "nombre": "Plato Trípode", "artista": "Cultura Precolombina", "descripcion": "Recipiente ceremonial de tres patas, utilizado para ofrendas y rituales."},
    "sala1_3": {"salaId": "sala1", "classIndex": 3, "roomName": "Sala 1 - Primeros Pobladores", "nombre": "Plato Trípode II", "artista": "Cultura Precolombina", "descripcion": "Segunda variante de vasija trípode con decoraciones particulares."},
    # Sala 2 — La Colonia
    "sala2_0": {"salaId": "sala2", "classIndex": 0, "roomName": "Sala 2 - La Colonia", "nombre": "Crucifijo", "artista": "NA", "descripcion": "Cruz cristiana tallada en madera, utilizada como símbolo central del cristianismo y empleada en ceremonias religiosas para la evangelización y enseñanza de los pueblos indígenas de la época."},
    "sala2_1": {"salaId": "sala2", "classIndex": 1, "roomName": "Sala 2 - La Colonia", "nombre": "Hacienda Chillo Compañía", "artista": "NA", "descripcion": "En el siglo XVII, las haciendas jesuitas del Valle de los Chillos se destacaron como las más productivas de la región. Desde sus inicios tuvieron gran importancia, pues albergaron y hospedaron a diversos científicos europeos que visitaron la zona."},
    "sala2_2": {"salaId": "sala2", "classIndex": 2, "roomName": "Sala 2 - La Colonia", "nombre": "Cacique Juan Zangolquí", "artista": "NA", "descripcion": "El Cacique de Urin Chillo, vivía en la cabecera del pueblo donde tenía 1135 personas sujetas a él. Casado con María Xumasa, tuvo 15 hijos."},
    "sala2_3": {"salaId": "sala2", "classIndex": 3, "roomName": "Sala 2 - La Colonia", "nombre": "Volcán Cotopaxi", "artista": "NA", "descripcion": "Representación artística del volcán Cotopaxi, el segundo volcán más alto de Ecuador con una altitud de 5897 metros sobre el nivel del mar, que se caracteriza por su cono simétrico cubierto de nieve y glaciares."},
    # Sala 3 — La Independencia
    "sala3_0": {"salaId": "sala3", "classIndex": 0, "roomName": "Sala 3 - La Independencia", "nombre": "Juan de Salinas", "artista": "Prócer Libertario Sangolquileño", "descripcion": "Militar e ilustrado criollo, considerado el primer comandante del ejército ecuatoriano. Lideró las milicias patrióticas y es reconocido como prócer de la Independencia. Nació en Conocoto y fue inscrito en Sangolquí."},
    "sala3_1": {"salaId": "sala3", "classIndex": 1, "roomName": "Sala 3 - La Independencia", "nombre": "Juan Pío Montúfar", "artista": "Marqués de Selva Alegre", "descripcion": "Integró la élite ilustrada de Quito y fue un importante promotor de la cultura, las ciencias y las ideas liberales. Tras el Primer Grito de Independencia asumió el cargo de regente, desempeñándose como director."},
    "sala3_2": {"salaId": "sala3", "classIndex": 2, "roomName": "Sala 3 - La Independencia", "nombre": "Rosa Montúfar", "artista": "Prócer Sangolquileña", "descripcion": "Símbolo femenino de la Independencia ecuatoriana. Prócer sangolquileña profundamente comprometida con la causa libertaria. Colaboró con las milicias patriotas proveyéndolas de armamento, incluidos fusiles nuevos."},
    "sala3_3": {"salaId": "sala3", "classIndex": 3, "roomName": "Sala 3 - La Independencia", "nombre": "Lucas Tipán", "artista": "El Chasqui Libertador", "descripcion": "Participó como guía, mensajero y espía al servicio del ejército libertador durante la campaña de liberación de la Real Audiencia de Quito."},
    # Sala 4 — El Maíz
    "sala4_0": {"salaId": "sala4", "classIndex": 0, "roomName": "Sala 4 - El Maíz", "nombre": "Planos del Maíz", "artista": "Gonzalo Endara Crow", "descripcion": "Planos arquitectónicos originales del monumento de \"El Choclo\", construido en 1989 realizada con hierro y hormigón."},
    "sala4_1": {"salaId": "sala4", "classIndex": 1, "roomName": "Sala 4 - El Maíz", "nombre": "Elemento de Control", "artista": "Control", "descripcion": "Elemento de control para el sistema de reconocimiento, utilizado para pruebas técnicas."},
    # Sala 5 — Plástica Ecuatoriana
    "sala5_0": {"salaId": "sala5", "classIndex": 0, "roomName": "Sala 5 - Plástica Ecuatoriana", "nombre": "El caballo azul - Réplica", "artista": "Gonzalo Endara Crow", "descripcion": "Nombre asignado por la comunidad, ya que Gonzalo Endara Crow no solía poner títulos a sus pinturas. La obra original se encuentra en Guayaquil y constituye un claro ejemplo de realismo mágico dentro de su producción pictórica."},
    "sala5_1": {"salaId": "sala5", "classIndex": 1, "roomName": "Sala 5 - Plástica Ecuatoriana", "nombre": "Retrato de Juan de Salinas", "artista": "Retrato Histórico", "descripcion": "Representación de Juan Salinas, prócer de la Independencia ecuatoriana. Participó de la gesta del Primer Grito de Independencia en Quito el 10 de agosto de 1809."},
    "sala5_2": {"salaId": "sala5", "classIndex": 2, "roomName": "Sala 5 - Plástica Ecuatoriana", "nombre": "La rendición", "artista": "Eduardo Kingman Riofrio", "descripcion": "Obra representativa en la que las manos simbolizan fuerza, lucha, trabajo, sacrificio y amor. Es atribuida al pintor ecuatoriano Eduardo Kingman, aunque no consta en la base de datos oficial de la familia Kingman."},
    "sala5_3": {"salaId": "sala5", "classIndex": 3, "roomName": "Sala 5 - Plástica Ecuatoriana", "nombre": "Retrato de Simón Bolívar", "artista": "Oswaldo Guayasamín", "descripcion": "Representación del Libertador Simón Bolívar, figura principal de la emancipación hispanoamericana del Imperio Español y fundador de las repúblicas de la Gran Colombia y Bolivia."},
    # Sala 6 — La Cantonización
    "sala6_0": {"salaId": "sala6", "classIndex": 0, "roomName": "Sala 6 - La Cantonización", "nombre": "Chagra", "artista": "Arte Tradicional", "descripcion": "Figura tradicional del campesino andino, símbolo del trabajo agrícola y de las actividades ganaderas. Representa la identidad cultural y la tradición popular del cantón Rumiñahui."},
    "sala6_1": {"salaId": "sala6", "classIndex": 1, "roomName": "Sala 6 - La Cantonización", "nombre": "Pingullero", "artista": "Música Tradicional", "descripcion": "Músico tradicional que entona el pingüllo y el tambor mama; convoca a la gente a importantes celebraciones como el Inti Raymi, Corpus Christi, entre otros."},
    "sala6_2": {"salaId": "sala6", "classIndex": 2, "roomName": "Sala 6 - La Cantonización", "nombre": "Ruco", "artista": "Sabiduría Ancestral", "descripcion": "Considerados hijos de la tierra, son símbolos de longevidad, sabiduría y tradición. Portadores de conocimientos y prácticas ancestrales, representan a los danzantes tradicionales de la región andina del Ecuador."},
}


def get_project_id():
    """Lee el project_id desde google-services.json."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    gs_path = os.path.join(script_dir, '..', 'android', 'app', 'google-services.json')
    gs_path = os.path.normpath(gs_path)
    if not os.path.exists(gs_path):
        print(f"❌ No encontré google-services.json en: {gs_path}")
        sys.exit(1)
    with open(gs_path, encoding='utf-8') as f:
        gs = json.load(f)
    return gs['project_info']['project_id']


def install_if_missing(package):
    """Instala un paquete pip si no está disponible."""
    import importlib
    try:
        importlib.import_module(package.replace('-', '_'))
    except ImportError:
        print(f"📥 Instalando {package}...")
        import subprocess
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', package, '-q'])
        print(f"✅ {package} instalado.\n")


def main():
    install_if_missing('firebase-admin')

    import firebase_admin
    from firebase_admin import credentials, firestore as fs

    project_id = get_project_id()
    print(f"🔥 Conectando a Firestore del proyecto: {project_id}\n")

    # Buscar service account si existe, sino usar ADC
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sa_path = os.path.join(script_dir, 'serviceAccountKey.json')
    sa_path = os.path.normpath(sa_path)

    if os.path.exists(sa_path):
        print(f"🔑 Usando Service Account: {sa_path}")
        cred = credentials.Certificate(sa_path)
        firebase_admin.initialize_app(cred)
    else:
        print("🔑 Usando Application Default Credentials (ADC)...")
        print("   (Si falla, descarga serviceAccountKey.json desde Firebase Console)")
        print("   Firebase Console → Project Settings → Service Accounts → Generate new private key")
        print(f"   Guárdalo como: scripts/serviceAccountKey.json\n")
        firebase_admin.initialize_app(options={'projectId': project_id})

    db = fs.client()

    print(f"🚀 Subiendo {len(artworks)} obras a Firestore...\n")
    count = 0
    for doc_id, data in artworks.items():
        db.collection('artworks').document(doc_id).set(data)
        count += 1
        print(f"  ✅ [{count:02d}/{len(artworks)}] {doc_id}: {data['nombre']}")

    print(f"\n🎉 ¡{count} obras subidas exitosamente!")
    print(f"   Colección: artworks")
    print(f"   Proyecto: {project_id}")


if __name__ == '__main__':
    main()
