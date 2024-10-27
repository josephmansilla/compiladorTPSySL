%{
#include <stdio.h> // manejo de E/S
#include <stdlib.h> // manejo de conversion de valores
#include <string.h> // manejo de conversion de string

extern char *yytext; // token recibido del lexico
extern int yyleng; // longitud del token

extern int yylex(void); // realiza el analisis lexico
extern void yyerror(char*); // prototipo de error

extern int yylineno; // linea del error
extern int yynerrs; // cantidad de errores sintacticos
extern int yylexerrs; // cantidad de errores lexicos
extern FILE* yyin; // archivo de entrada de extension .m

void asignarIDs(char* cadena, int num);

struct Identificador{
    char* cadena;
    int num;
};

struct Identificador vectorIdentificadores[100];
int cantID = 0;

%}

%union{
   char* cadena;
   int num;
} 
%token ASIGNACION INICIO FIN LEER ESCRIBIR COMA PUNTOYCOMA SUMA RESTA MULTIPLICACION DIVISION PARENIZQUIERDO PARENDERECHO FDT
%token <cadena> ID
%token <num> CONSTANTE

%type <num> sentencia listaExpresiones expresion termino factor


%%
programa: 
    INICIO listaSentencias FIN {if (yynerrs || yylexerrs){ printf("\nSe deja de procesar...\n"); YYABORT; }}
    ;

listaSentencias: 
    listaSentencias sentencia 
    | sentencia
    ;

sentencia: 
    ID {if(yyleng>32){printf("\nError léxico: se excedió la longitud máxima para un identificador\n"); yylexerrs++;}} ASIGNACION expresion PUNTOYCOMA
    { 
        int num = $4; 
        char* cadena = $1;
        asignarIDs(cadena, num);
    }
    | LEER PARENIZQUIERDO listaExpresiones PARENDERECHO PUNTOYCOMA
    {
        int numero;
        char* cadena = $<cadena>3;
        char* token = strtok(cadena, ", ");
        while(token!=NULL){
            printf("\nIngresar valor del identificador '%s': ",token);
            scanf("%d", &numero);
            asignarIDs(token, numero);
            token = strtok(NULL, ", ");
        }
    }
    
    
    | ESCRIBIR PARENIZQUIERDO listaExpresiones PARENDERECHO PUNTOYCOMA {}
    ;

listaExpresiones: 
    listaExpresiones COMA expresion {printf("\n%i\n", $3);}
    | expresion {printf("\n%i\n", $1);}
    ;

expresion: 
    expresion SUMA termino {$$ = $1 + $3;}
    | expresion RESTA termino {$$ = $1 - $3;}
    | termino 
    ;

termino:
    termino MULTIPLICACION factor {$$ = $1 * $3;}
    | termino DIVISION factor {if ($3 != 0) $$ = $1 / $3; else $$=$1;}
    | factor 
    ;

factor: 
    PARENIZQUIERDO expresion PARENDERECHO {$$ = $2;}
    | CONSTANTE 
    | ID
    {
        char* cadena = $<cadena>1;
        int j;
        for(j=0; j < cantID; j++){
            if(strcmp(vectorIdentificadores[j].cadena, cadena)==0){
                $$ = vectorIdentificadores[j].num;
            }
        }
    }
    ;



%%

void yyerror(char *string){
        fprintf(stderr, "\nError sintáctico: %s en la línea %d\n", string, yylineno);
        if (yytext) {
            fprintf(stderr, "                -> Provocado por el token: %s\n", yytext);
    }
}


int main(int argc, char** argv){ 
    // contador de argumentos (argc)
    // array de punteros a cadena de chars (char** argv ó char[][] argv -> esta ya es una matriz)

    if ( argc == 1 ){
        printf("\nDebe ingresar el nombre del archivo fuente (en lenguaje Micro) en la línea de comandos\n");
        return -1;
    }

    else if ( argc != 2 ){
      printf("\nNúmero incorrecto de argumentos\n");
      return -1;
    }

    char nombreArchivo[50];

    sprintf(nombreArchivo, "%s", argv[1]);
    int largoArchivo = strlen(nombreArchivo);


    if (argv[1][largoArchivo-1] != 'm' || argv[1][largoArchivo-2] != '.'){ 
        printf("\nExtensión incorrecta (debe ser .m)\n");
        return EXIT_FAILURE;
    }

    if ((yyin = fopen(nombreArchivo, "r")) == NULL){
        perror("\nError al abrir el archivo\n");
        return EXIT_FAILURE;
    }
   
    switch (yyparse()){
        case 0: printf("\n%%%% Proceso de compilación terminó éxitosamente %%%%\n");
        break;
        case 1: printf("\n%%%% Errores en la compilación %%%%\n");
        break;
        case 2: printf("\nNo hay memoria suficiente");
        break;
    }

    printf("\n     @ Errores sintácticos: %i\n     @ Errores léxicos: %i\n", yynerrs, yylexerrs);

    fclose(yyin);
    return 0;
}

void asignarIDs(char* cadena, int num){
    int i;
    for(i = 0; i < cantID; i++){
        if(strcmp(vectorIdentificadores[i].cadena, cadena)==0){
            vectorIdentificadores[i].num = num;
            break;
        }
    }
    if (i == cantID){
        vectorIdentificadores[cantID].cadena = cadena;
        vectorIdentificadores[cantID].num = num;
        cantID++;
    }
}