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
%}

%union{
   char* cadena;
   int num;
} 
%token ASIGNACION INICIO FIN LEER ESCRIBIR COMA PUNTOYCOMA SUMA RESTA MULTIPLICACION DIVISION PARENIZQUIERDO PARENDERECHO
%token <cadena> ID
%token <num> CONSTANTE

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
    | LEER PARENIZQUIERDO listaExpresiones PARENDERECHO PUNTOYCOMA 
    | ESCRIBIR PARENIZQUIERDO listaExpresiones PARENDERECHO PUNTOYCOMA
    ;

listaExpresiones: 
    listaExpresiones COMA expresion 
    |expresion
    ;

expresion: 
    expresion operadorAditivo termino
    |termino 
    ;

termino:
    termino operadorMultiplicativo factor
    |factor
    ;

factor: 
    PARENIZQUIERDO expresion PARENDERECHO
    |CONSTANTE 
    |ID
    ;

operadorAditivo: 
    SUMA 
    |RESTA
    ;

operadorMultiplicativo:
    MULTIPLICACION 
    |DIVISION
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

