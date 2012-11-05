%{
#include <stdio.h>

int iLine = 1;
int iCol = 1;
int iTS = 8;
FILE *fOut = NULL;

#define YY_USER_ACTION  { iCol += yyleng; }
#define wl( s, i )      (fwrite( s, 1, i, fOut ))
#define wyy             (wl( yytext, yyleng ))
%}
%option nounput noyywrap
%x dq
%%
\t          {
    iCol--;
    int x, tc=iTS-((iCol-1)%iTS);
    if( tc == 0 )
        tc = iTS;
    for( x = 0; x < tc; x++ )
        wl(" ", 1 );
    iCol += tc;
    }
\n          { wyy; iCol = 1; iLine++; }
[^\t\n\"]*	{ wyy; }
\"          { wyy; BEGIN(dq); }
<dq>\"		{ wyy; BEGIN(INITIAL); }
<dq>[^\"]* { wyy; }
%%

int main( int argc, char *argv[] )
{
    char **p, *sIn=NULL, *sOut=NULL, *sTmp=NULL;
    int bInPlace = 0;
    int bKeepBackup = 0;

    fOut = stdout;
    yyin = stdin;
    
    argc--, argv++;
    for( p = argv; *p; p++ )
    {
        if( (*p)[0] == '-' )
        {
            switch( (*p)[1] )
            {
                case 't':
                    iTS = strtol( *(++p), NULL, 10 );
                    break;

                case 'i':
                    bInPlace = -1;
                    break;

                case 'k':
                    bKeepBackup = -1;
                    break;

                case 'h':
                    printf("tabconv [options] <input> <output>\n\n"
                        "  -t <tabsize>     Set the tabsize (default 8 "
                            "spaces).\n"
                        "  -i               Process in-place, only specify "
                            "the input file.\n"
                        "  -k               If -i is specified then the "
                            "backup file is not deleted.\n"
                        "  -h               This help.\n\n"
                        "If no input or output are provided then standard "
                            "in/out are used.\n\n"
                        );
                    return 0;
                    break;
            }
        }
        else
        {
            if( !sIn )
            {
                sIn = *p;
            }
            else if( !sOut )
            {
                sOut = *p;
            }
            else
            {
                fprintf( stderr, "Confused by extra parameter: %s\n", *p );
                return 1;
            }
        }
    }

    if( bInPlace )
    {
        if( sOut )
        {
            fprintf( stderr,
                "You cannot specify -i (in-place) and an output file.\n"
                );
            return 1;
        }
        sTmp = malloc( strlen( sIn )+2 );
        strcpy( sTmp, sIn );
        strcat( sTmp, "~");
        if( rename( sIn, sTmp ) )
        {
            fprintf( stderr,
                "Cannot create temporary backup of input: %s\n",
                strerror( errno )
                );
            return 1;
        }
        sOut = sIn;
        sIn = sTmp;
    }

    if( sIn )
    {
        yyin = fopen( sIn, "r" );
        if( yyin == NULL )
        {
            fprintf( stderr, "Cannot open input file '%s': %s\n",
                sIn, strerror( errno ) );
            return 1;
        }
    }

    if( sOut )
    {
        fOut = fopen( sOut, "w" );
        if( fOut == NULL )
        {
            fprintf( stderr, "Cannot open output file '%s': %s\n",
                sOut, strerror( errno ) );
            return 1;
        }
    }

    while( yylex() ) { }

    if( yyin != stdin )
        fclose( yyin );
    if( fOut != stdout )
        fclose( fOut );


    if( bInPlace && !bKeepBackup )
    {
        unlink( sIn );
    }


    return 0;
}

