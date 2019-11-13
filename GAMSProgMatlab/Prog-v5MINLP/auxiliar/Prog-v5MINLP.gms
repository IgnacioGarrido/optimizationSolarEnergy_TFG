SET
         I HORAS /1*24/;

PARAMETERS  CARGAINICIAL , HORASALIDA , HORALLEGADA ;
PARAMETER PERIODOESTACIONADO(I) ;


*Par�metros inventados...Falta sacar los valores reales
PARAMETERS
*Precio por KWh
  PRECIOENERGIA(I) precio energ�a  /1       3.
                         2       3.
                         3       4.
                         4       3.
                         5       3.
                         6       4.
                         7       4.
                         8       6.
                         9       8.
                         10      10.
                         11      10.
                         12      9.
                         13      7.
                         14      6.
                         15      6.
                         16      8.
                         17      10.
                         18      11.
                         19      12.
                         20      10.
                         21      8.
                         22      3.
                         23      3.
                         24      3. /

*Producci�n fotovoltaica de la escuela / hora
  PRODUCCIONFOTOVOLTAICA(I) p. fotovoltaica /1       0.
                         2       0.
                         3       0.
                         4       0.
                         5       0.
                         6       0.
                         7       0.
                         8       1.
                         9       2.
                         10      3.
                         11      3.5
                         12      4.
                         13      4.3
                         14      4.5
                         15      4.5
                         16      4.4
                         17      4.
                         18      3.5
                         19      2.
                         20      1.
                         21      0.
                         22      0.
                         23      0.
                         24      0. /

*Consumo de la escuela / hora
  CONSUMOESCUELA(I) consumo escuela /1       50.
                         2       60.
                         3       70.
                         4       60.
                         5       70.
                         6       70.
                         7       90.
                         8       110.
                         9       130.
                         10      100.
                         11      100.
                         12      90.
                         13      80.
                         14      60.
                         15      60.
                         16      80.
                         17      90.
                         18      100.
                         19      150.
                         20      130.
                         21      80.
                         22      30.
                         23      30.
                         24      30. /
 FOTOVOLTAICASUPERIOR(I)    Vector con un 1 en las posiciones en las que hay m�s producci�n que consumo
;


SCALAR
         CAPACIDAD               Capacidad de la bater�a en kWh  /24/
         CARGAALASALIDA          Carga minima cuando se va       /18/
         COUNTERLOOP             Contador para el loop           /0/
         NUMCOCHES               N�mero de coches                /1/
         RATIOCARGADESCARGA      KWh m�ximos en 1 hora           /3.68/;

*LOOP para completar el vector FOTOVOLTAICASUPERIOR. Tiene un 1 si la producci�n
*fotovolt�ica en la hora I es menor que el consumo, y un 0 en caso contrario
LOOP(I, if ((CONSUMOESCUELA(I) + (NUMCOCHES*RATIOCARGADESCARGA)) < PRODUCCIONFOTOVOLTAICA(I) , FOTOVOLTAICASUPERIOR(I) = 0;
        else FOTOVOLTAICASUPERIOR(I) = 1;);
    );

VARIABLES
F;

POSITIVE VARIABLES
CARGA(I), CONSUMOPORHORA(I);

BINARY VARIABLES
COCHEACEPTADO;

*fx para fijar el valor de una variable.
*Este loop inicializa el valor de la carga con CARGAINICIAL.
*Fija ese valor en todas las horas hasta que llega.
LOOP(I, COUNTERLOOP = COUNTERLOOP+1;
        if (COUNTERLOOP <= HORALLEGADA, CARGA.fx(I) =  CARGAINICIAL;);
        if (COUNTERLOOP = 24, COUNTERLOOP = 0;);
    );

*lo para poner el l�mite inferior de una variable.
*Este loop pone un l�mite inferior a la carga de salida. Aseguramos que el
*coche se va con una carga m�nima.
*PARA SIMULACIONES 2.1 Y 3.1 CAMBIAR CARGAALASALIDA POR CARGAINICIAL(J).
LOOP(I, COUNTERLOOP = COUNTERLOOP+1;
        if (COUNTERLOOP >= HORASALIDA, CARGA.fx(I) =  CARGAALASALIDA;);
        if (COUNTERLOOP = 24, COUNTERLOOP = 0;);
    );

EQUATIONS
     OBJ                         La funci�n objetivo
     ITERACIONCOCHEACEPTADO(I)   Funci�n de las horas 1 a la 24 que incluye la variable binaria COCHEACEPTADO(I)
     CAPACIDADMAX(I)             Funci�n que condiciona la carga de la bater�a a la capacidad
     CARGAMAX(I)                 Funci�n que condiciona la carga  por hora m�xima a 3.68 kWh
     DESCARGAMAX(I)              Funci�n que condiciona la descarga  por hora m�xima a 3.68 kWh
     NODESCARGADEBAJO(I)         Funci�n que no permite descarga por debajo de la carga con la que llega el coche
;

OBJ ..                           F  =E=  sum(I, CONSUMOPORHORA(I));

ITERACIONCOCHEACEPTADO(I) ..     FOTOVOLTAICASUPERIOR(I)*(PRECIOENERGIA(I)*[CONSUMOESCUELA(I) - PRODUCCIONFOTOVOLTAICA(I) + sum(J,COCHEACEPTADO(J)*[[CARGA(J,I) - CARGA(J,I-1)]*PERIODOESTACIONADO(J,I)])]) =E=  CONSUMOPORHORA(I) ;

CAPACIDADMAX(I) ..               CARGA(I) =L= CAPACIDAD;

CARGAMAX(I) ..                   CARGA(I+1) - CARGA(I) =L= RATIOCARGADESCARGA;

DESCARGAMAX(I) ..                CARGA(I) - CARGA(I-1) =G= -RATIOCARGADESCARGA;

NODESCARGADEBAJO(I) ..           CARGA(I) =G= CARGAINICIAL(J);

MODEL progConCoches4 /OBJ, ITERACIONCOCHEACEPTADO, CAPACIDADMAX, CARGAMAX, DESCARGAMAX/ ;
MODEL progConCoches5 /OBJ, ITERACIONCOCHEACEPTADO, CAPACIDADMAX, CARGAMAX, DESCARGAMAX, NODESCARGADEBAJO/ ;

SOLVE progConCoches4 using MINLP minimizing F;
*SOLVE progConCoches5 using MINLP minimizing F;
