

double  solve(
  double (*f)(), /* pointer to function to be solved */
  double a,      /* minimum value of solution */
  double b,      /* maximum value of solution */
  double err,    /* accuarcy of solution */
  int *code      /* error code */
  );
