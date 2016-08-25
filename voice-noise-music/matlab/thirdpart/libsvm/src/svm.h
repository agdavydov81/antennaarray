#ifndef _LIBSVM_H
#define _LIBSVM_H

#define LIBSVM_VERSION 321

#ifdef __cplusplus
extern "C" {
#endif

extern int libsvm_version;

#ifdef _DENSE_REP
struct svm_node
{
	int dim;
	double *values;
};

struct svm_problem
{
	int l;
	double *y;
	struct svm_node *x;
};

#else
struct svm_node
{
	int index;
	double value;
};

struct svm_problem
{
	int l;
	double *y;
	struct svm_node **x;
};
#endif

enum { C_SVC, NU_SVC, ONE_CLASS, EPSILON_SVR, NU_SVR };	/* svm_type */
enum { LINEAR, POLY, RBF, SIGMOID, PRECOMPUTED }; /* kernel_type */

struct svm_parameter
{
#ifdef __cplusplus
	svm_parameter()
		: svm_type(C_SVC)
		, kernel_type(RBF)
		, degree(3)
		, gamma(0)
		, coef0(0)
		, cache_size(100)
		, eps(1e-3)
		, C(1)
		, nr_weight(0)
		, weight_label(NULL)
		, weight(NULL)
		, nu(0.5)
		, p(0.1)
		, shrinking(1)
		, probability(0)
		, rnd_seed(0)
		, max_iter(0)
		, timeout_sec(0)
		, printf_output(0)
	{}
#endif

	int svm_type;
	int kernel_type;
	int degree;	/* for poly */
	double gamma;	/* for poly/rbf/sigmoid */
	double coef0;	/* for poly/sigmoid */

	/* these are for training only */
	double cache_size; /* in MB */
	double eps;	/* stopping criteria */
	double C;	/* for C_SVC, EPSILON_SVR and NU_SVR */
	int nr_weight;		/* for C_SVC */
	int *weight_label;	/* for C_SVC */
	double* weight;		/* for C_SVC */
	double nu;	/* for NU_SVC, ONE_CLASS, and NU_SVR */
	double p;	/* for EPSILON_SVR */
	int shrinking;	/* use the shrinking heuristics */
	int probability; /* do probability estimates */
	int rnd_seed; /* random number generator seed: 0 - rdtsc */
	int max_iter; /* stopping train maximum iterations number */
	int timeout_sec; /* one model train timeout in seconds (0 - no limit) */
	int printf_output; /* show library messages and warnings (via printf) */
};

struct svm_train_stat
{
#ifdef __cplusplus
	svm_train_stat()
		: iter_num(0)
		, train_time_sec(0)
		, models_num(0)
	{}
	svm_train_stat(int iter_num_, int train_time_sec_, int models_num_)
		: iter_num(iter_num_)
		, train_time_sec(train_time_sec_)
		, models_num(models_num_)
	{}

	svm_train_stat & operator += (svm_train_stat const &rhs) {
		int64_t iter_num64 = iter_num + rhs.iter_num;
		iter_num = (int)iter_num64;
		if (iter_num < iter_num64)
			iter_num = INT_MAX;

		int64_t train_time_sec64 = train_time_sec + rhs.train_time_sec;
		train_time_sec = (int)train_time_sec64;
		if (train_time_sec < train_time_sec64)
			train_time_sec = INT_MAX;

		int64_t models_num64 = models_num + rhs.models_num;
		models_num = (int)models_num64;
		if (models_num < models_num64)
			models_num = INT_MAX;

		return *this;
	}
#endif

	int		iter_num;
	int		train_time_sec;
	int		models_num;
};

//
// svm_model
// 
struct svm_model
{
	struct svm_parameter param;	/* parameter */
	int nr_class;		/* number of classes, = 2 in regression/one class svm */
	int l;			/* total #SV */
#ifdef _DENSE_REP
	struct svm_node *SV;		/* SVs (SV[l]) */
#else
	struct svm_node **SV;		/* SVs (SV[l]) */
#endif
	double **sv_coef;	/* coefficients for SVs in decision functions (sv_coef[k-1][l]) */
	double *rho;		/* constants in decision functions (rho[k*(k-1)/2]) */
	double *probA;		/* pairwise probability information */
	double *probB;
	int *sv_indices;        /* sv_indices[0,...,nSV-1] are values in [1,...,num_traning_data] to indicate SVs in the training set */

	/* for classification only */

	int *label;		/* label of each class (label[k]) */
	int *nSV;		/* number of SVs for each class (nSV[k]) */
				/* nSV[0] + nSV[1] + ... + nSV[k-1] = l */
	/* XXX */
	int free_sv;		/* 1 if svm_model is created by svm_load_model*/
				/* 0 if svm_model is created by svm_train */
};

struct svm_model *svm_train(const struct svm_problem *prob, const struct svm_parameter *param, struct svm_train_stat *stat_ret);
void svm_cross_validation(const struct svm_problem *prob, const struct svm_parameter *param, struct svm_train_stat *stat_ret, int nr_fold, double *target);

int svm_save_model(const char *model_file_name, const struct svm_model *model);
struct svm_model *svm_load_model(const char *model_file_name);

int svm_get_svm_type(const struct svm_model *model);
int svm_get_nr_class(const struct svm_model *model);
void svm_get_labels(const struct svm_model *model, int *label);
void svm_get_sv_indices(const struct svm_model *model, int *sv_indices);
int svm_get_nr_sv(const struct svm_model *model);
double svm_get_svr_probability(const struct svm_model *model);

double svm_predict_values(const struct svm_model *model, const struct svm_node *x, double* dec_values);
double svm_predict(const struct svm_model *model, const struct svm_node *x);
double svm_predict_probability(const struct svm_model *model, const struct svm_node *x, double* prob_estimates);

void svm_free_model_content(struct svm_model *model_ptr);
void svm_free_and_destroy_model(struct svm_model **model_ptr_ptr);
void svm_destroy_param(struct svm_parameter *param);

const char *svm_check_parameter(const struct svm_problem *prob, const struct svm_parameter *param);
int svm_check_probability_model(const struct svm_model *model);

#ifdef __cplusplus
}
#endif

#endif /* _LIBSVM_H */
