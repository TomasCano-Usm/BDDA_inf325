"""Genera 30 actores ficticios, JSON y CQL reproducibles; --insertar carga Cassandra."""
import argparse
from datetime import date
from uuid import UUID, uuid5
import json
from comun import BASE, ejecutar_cql, insertar_actor, insertar_personaje

ESPACIO = UUID('36d9ab6d-076d-4bde-a004-fcf6a1c2e477')
FECHA_REFERENCIA = date(2026, 10, 8)
NOMBRES = [
    'Amalia Rojas', 'Bruno Vidal', 'Camila Soto', 'Diego Araya', 'Elena Flores',
    'Felipe Lagos', 'Gabriela Vera', 'Hector Salas', 'Isidora Leon', 'Javier Ruiz',
    'Kaori Mori', 'Ren Takeda', 'Hana Sato', 'Yuki Arai', 'Sora Fujita',
    'Mateo Luna', 'Lucia Solis', 'Emilia Cruz', 'Nicolas Vega', 'Valeria Rios',
    'Oliver Reed', 'Emma Brooks', 'Noah Parker', 'Mia Collins', 'Liam Hayes',
    'Sofia Martin', 'Pablo Torres', 'Clara Gil', 'Adrian Serra', 'Alba Costa',
]
EDADES = [24, 40, 32, 51, 28, 60, 39, 45, 22, 36, 26, 42, 30, 54, 38,
          29, 41, 35, 58, 27, 33, 48, 23, 44, 37, 25, 50, 31, 46, 34]


def generar():
    actores = []
    for i, (nombre, edad) in enumerate(zip(NOMBRES, EDADES)):
        pais = 'Chile' if i < 10 else ['Japon', 'Mexico', 'Estados Unidos', 'Espana'][(i - 10) // 5]
        idioma = {'Chile': 'Espanol', 'Japon': 'Japones', 'Mexico': 'Espanol',
                  'Estados Unidos': 'Ingles', 'Espana': 'Espanol'}[pais]
        # Cumpleanos ya ocurrido en la fecha de referencia; edad coherente.
        nacimiento = date(2026 - edad, 1 + i % 9, 1 + i % 25)
        actor_id = str(uuid5(ESPACIO, f'actor-{i + 1:02d}'))
        actor = dict(actor_id=actor_id, nombre=nombre, nacionalidad=pais,
                     fecha_nacimiento=nacimiento.isoformat(), edad=edad,
                     patrimonio=100000 + i * 27500,
                     idiomas=sorted({idioma, 'Ingles'} if i % 2 == 0 else {idioma}))
        actor['personajes'] = []
        for j in range(3):
            actor['personajes'].append(dict(
                personaje_id=str(uuid5(ESPACIO, f'personaje-{i + 1}-{j + 1}')),
                nombre_personaje=['Astra', 'Nimbo', 'Lumen'][j],
                produccion=['Guardianes del Alba', 'Orbita Azul', 'Bosque de Papel'][j],
                tipo_produccion='independiente' if j == 2 else 'profesional',
                rol='secundario' if j == 2 else 'principal',
                apariciones=[24 + i % 9, 12 + i % 6, 5 + i % 4][j],
                generos=[['Animacion', 'Aventura'], ['Animacion', 'Ciencia ficcion'],
                         ['Animacion', 'Fantasia']][j]))
        actores.append(actor)
    return actores


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--insertar', action='store_true')
    args = parser.parse_args()
    actores = generar()
    carpeta = BASE / 'datos'
    carpeta.mkdir(exist_ok=True)
    (carpeta / 'actores.json').write_text(json.dumps(actores, ensure_ascii=False, indent=2), encoding='utf-8')
    sentencias = ['USE actors;', 'CONSISTENCY QUORUM;']
    for actor in actores:
        sentencias.extend(insertar_actor(actor))
        sentencias.extend(insertar_personaje(actor['actor_id'], p) for p in actor['personajes'])
    cql = '\n'.join(sentencias)
    (carpeta / 'insertar_datos.cql').write_text(cql + '\n', encoding='utf-8')
    if args.insertar:
        ejecutar_cql(cql, '02_carga_datos')
    print(f'Generados {len(actores)} actores y {sum(len(a["personajes"]) for a in actores)} personajes.')
    print(f'Actor de ejemplo: {actores[0]["actor_id"]}')


if __name__ == '__main__':
    main()
