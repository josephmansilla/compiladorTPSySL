%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h> 

extern char *yytext; 
extern int yyleng;

extern int yylex(void); 
extern void yyerror(char*); 

extern int yylineno; 
extern int yynerrs;
extern int yylexerrs; 
extern FILE* yyin; 

int tabla_simbolos[26];  
%}

%union{
   char* cadena;
   int num;
} 
%token ASIGNACION INICIO FIN LEER ESCRIBIR COMA PUNTOYCOMA SUMA RESTA MULTIPLICACION DIVISION PARENIZQUIERDO PARENDERECHO
%token <cadena> ID
%token <num> CONSTANTE

%type <num> sentencia listaExpresiones expresion termino factor

%left SUMA RESTA
%left MULTIPLICACION DIVISION

%%
programa: 
    INICIO listaSentencias FIN  {if (yynerrs || yylexerrs) printf("\nSe Detiene...\n"); YYABORT;}
    ;

listaSentencias: 
    listaSentencias sentencia 
    |sentencia
    ;

sentencia: 
    ID {if(yyleng>32){ printf("\nError lexico: se excedio la longitud maxima para un identificador\n"); yylexerrs++;}} ASIGNACION expresion PUNTOYCOMA
    { 
        tabla_simbolos[($1)[0] - 'A'] = $4 ; 
    }
    | LEER PARENIZQUIERDO listaExpresiones PARENDERECHO PUNTOYCOMA {}
    | ESCRIBIR PARENIZQUIERDO listaExpresiones PARENDERECHO PUNTOYCOMA {}
    ;

listaExpresiones: 
    listaExpresiones COMA expresion {printf("%i\n", $3);}
    |expresion {printf("%i\n", $1);}
    ;

expresion: 
    expresion SUMA termino {$$ = $1 + $3;}
    |expresion RESTA termino {$$ = $1 - $3;}
    |termino {$$=$1;}
    ;

termino:
    termino MULTIPLICACION factor {$$ = $1 * $3;}
    |termino DIVISION factor {if ($3>0) $$ = $1 / $3; else $$=$1;}
    |factor {$$=$1;}
    ;

factor: 
    PARENIZQUIERDO expresion PARENDERECHO {$$ = $2;}
    |CONSTANTE {$$ = $1;}
    |ID {$$ = tabla_simbolos[(*$1) - 'A'];}
    ;



%%

void yyerror(char *s){
    fprintf(stderr, "\nError sintactico: %s en la linea %d\n", s, yylineno);
      if (yytext) {
        fprintf(stderr, "                -> Provocado por el token: %s\n", yytext);
    }
}


int main(int argc, char** argv){ 

    if ( argc == 1 ){
        printf("\nDebe ingresar el nombre del archivo fuente (en lenguaje Micro) en la linea de comandos\n");
        return -1;
    }

    else if ( argc != 2 ){
      printf("\nNumero incorrecto de argumentos\n");
      return -1;
    }

    char nombreArchivo[50];

    sprintf(nombreArchivo, "%s", argv[1]);
    int largoArchivo = strlen(nombreArchivo);


    if (argv[1][largoArchivo-1] != 'm' || argv[1][largoArchivo-2] != '.'){ 
        printf("\nExtension incorrecta (debe ser .m)\n");
        return EXIT_FAILURE;
    }

    if ((yyin = fopen(nombreArchivo, "r")) == NULL){
        perror("\nError al abrir el archivo\n");
        return EXIT_FAILURE;
    }
   
    switch (yyparse()){
        case 0: printf("\n%%% Proceso de compilacion termino exitosamente %%%");
        break;
        case 1: printf("\n%%%% Errores en la compilacion %%%%\n");
        break;
        case 2: printf("\nNo hay memoria suficiente");
        break;
    }

    printf("\n   @ Errores sintacticos: %i\n   @ Errores lexicos: %i\n", yynerrs, yylexerrs);

    fclose(yyin);
    return 0;
}

