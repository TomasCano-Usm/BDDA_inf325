"""Aumenta patrimonio 32% y agrega Sansa; plan persistente permite reintentar sin duplicar aumento."""
from decimal import Decimal, ROUND_HALF_UP
from uuid import uuid5
import json
from comun import BASE, EVIDENCIAS, ejecutar_cql, filas_json, insertar_personaje, literal
from generar_datos import ESPACIO


def main():
    EVIDENCIAS.mkdir(exist_ok=True)
    ruta = EVIDENCIAS / 'plan_actualizacion.json'
    if ruta.exists():
        plan = json.loads(ruta.read_text(encoding='utf-8'))
        print('Reutilizando plan: se asignan valores absolutos, no se vuelve a multiplicar.')
    else:
        # Recorrido administrativo de todas las filas: necesario para actualizar TODOS los actores.
        actores = filas_json('SELECT JSON actor_id, nombre, nacionalidad, edad, patrimonio FROM actors.actores_por_id;')
        if len(actores) < 20:
            raise RuntimeError('Se requieren al menos 20 actores cargados.')
        plan = []
        for a in actores:
            nuevo = (Decimal(str(a['patrimonio'])) * Decimal('1.32')).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
            plan.append({**a, 'patrimonio_anterior': str(a['patrimonio']), 'patrimonio_nuevo': str(nuevo),
                         'rol': 'principal' if a['edad'] < 40 else 'secundario',
                         'apariciones': 3 if a['edad'] < 40 else 1})
        ruta.write_text(json.dumps(plan, ensure_ascii=False, indent=2), encoding='utf-8')
    sentencias = ['CONSISTENCY QUORUM;']
    for a in plan:
        sentencias.extend([
            f"UPDATE actors.actores_por_id SET patrimonio = {a['patrimonio_nuevo']} WHERE actor_id = {a['actor_id']};",
            f"UPDATE actors.actores_por_nacionalidad SET patrimonio = {a['patrimonio_nuevo']} "
            f"WHERE nacionalidad = {literal(a['nacionalidad'])} AND edad = {a['edad']} AND actor_id = {a['actor_id']};",
            insertar_personaje(a['actor_id'], dict(
                personaje_id=str(uuid5(ESPACIO, a['actor_id'] + '-sansa')),
                rol=a['rol'], apariciones=a['apariciones'], nombre_personaje='Sansa',
                produccion='Sansa Ball Race', tipo_produccion='profesional', generos=['Animacion']))])
    ejecutar_cql('\n'.join(sentencias), '24_actualizacion')
    print(f'Actualizados {len(plan)} actores: dos copias de patrimonio y una participacion por actor.')


if __name__ == '__main__':
    main()
