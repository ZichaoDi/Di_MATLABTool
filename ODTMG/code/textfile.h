
int is_int(char *buf);
int is_double(char *buf);
int read_next_word(FILE *fp, char *buf);
int read_next_int(FILE *fp, int *readme);
int read_next_int_or_brace(FILE *fp, int *readme);
int read_next_double(FILE *fp, double *readme);
int lookfor(FILE *fp,  char *findme);
int get_source(FILE *fp, src_param *source);
int get_detector(FILE *fp, det_param *det);
int get_phys(FILE *fp, phys_param *phys);

int get_config(FILE *fp, config_param *config);

int get_connections(FILE *fp, phys_param *phys, src_param *src, det_param *det);
phys_param *alloc_phys_param(void);
void delete_phys_param(phys_param *phys);

void get_all_phys(FILE *fp, phys_param *phys, src_param **src_ptr, det_param **det_ptr);

int get_prior(FILE *fp, prior_param *prior );
