import os

files = ['VENTAS.csv', 'CLIENTES.csv', 'EMPLEADOS.csv', 
         'MUNICIPIOS.csv', 'CATALOGO_PRODUCTOS.csv', 
         'TIENDAS.csv', 'LINEAS_VENTA.csv']

for f in files:
    with open(f, 'r', encoding='cp1252', errors='replace') as fp:
        content = fp.read()
    with open(f, 'w', encoding='utf-8') as fp:
        fp.write(content)
    print(f'Convertido: {f}')