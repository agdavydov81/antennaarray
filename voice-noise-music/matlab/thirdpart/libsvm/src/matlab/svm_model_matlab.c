#include <stdlib.h>
#include <string.h>
#include "svm.h"

#include "mex.h"

#ifdef MX_API_VER
#if MX_API_VER < 0x07030000
typedef int mwIndex;
#endif
#endif

#define NUM_OF_RETURN_FIELD 11

#define Malloc(type,n) (type *)malloc((n)*sizeof(type))

static const char *field_names[] = {
	"Parameters",
	"nr_class",
	"totalSV",
	"rho",
	"Label",
	"sv_indices",
	"ProbA",
	"ProbB",
	"nSV",
	"sv_coef",
	"SVs"
};

const char *model_to_matlab_structure(mxArray *plhs[], int num_of_feature, struct svm_model *model)
{
	int i, j, n;
	double *ptr;
	mxArray *return_model, **rhs;
	int out_id = 0;

	rhs = (mxArray **)mxMalloc(sizeof(mxArray *)*NUM_OF_RETURN_FIELD);

	// Parameters
	rhs[out_id] = mxCreateDoubleMatrix(5, 1, mxREAL);
	ptr = mxGetPr(rhs[out_id]);
	ptr[0] = model->param.svm_type;
	ptr[1] = model->param.kernel_type;
	ptr[2] = model->param.degree;
	ptr[3] = model->param.gamma;
	ptr[4] = model->param.coef0;
	out_id++;

	// nr_class
	rhs[out_id] = mxCreateDoubleMatrix(1, 1, mxREAL);
	ptr = mxGetPr(rhs[out_id]);
	ptr[0] = model->nr_class;
	out_id++;

	// total SV
	rhs[out_id] = mxCreateDoubleMatrix(1, 1, mxREAL);
	ptr = mxGetPr(rhs[out_id]);
	ptr[0] = model->l;
	out_id++;

	// rho
	n = model->nr_class*(model->nr_class-1)/2;
	rhs[out_id] = mxCreateDoubleMatrix(n, 1, mxREAL);
	ptr = mxGetPr(rhs[out_id]);
	for(i = 0; i < n; i++)
		ptr[i] = model->rho[i];
	out_id++;

	// Label
	if(model->label)
	{
		rhs[out_id] = mxCreateDoubleMatrix(model->nr_class, 1, mxREAL);
		ptr = mxGetPr(rhs[out_id]);
		for(i = 0; i < model->nr_class; i++)
			ptr[i] = model->label[i];
	}
	else
		rhs[out_id] = mxCreateDoubleMatrix(0, 0, mxREAL);
	out_id++;

	// sv_indices
	if(model->sv_indices)
	{
		rhs[out_id] = mxCreateDoubleMatrix(model->l, 1, mxREAL);
		ptr = mxGetPr(rhs[out_id]);
		for(i = 0; i < model->l; i++)
			ptr[i] = model->sv_indices[i];
	}
	else
		rhs[out_id] = mxCreateDoubleMatrix(0, 0, mxREAL);
	out_id++;

	// probA
	if(model->probA != NULL)
	{
		rhs[out_id] = mxCreateDoubleMatrix(n, 1, mxREAL);
		ptr = mxGetPr(rhs[out_id]);
		for(i = 0; i < n; i++)
			ptr[i] = model->probA[i];
	}
	else
		rhs[out_id] = mxCreateDoubleMatrix(0, 0, mxREAL);
	out_id ++;

	// probB
	if(model->probB != NULL)
	{
		rhs[out_id] = mxCreateDoubleMatrix(n, 1, mxREAL);
		ptr = mxGetPr(rhs[out_id]);
		for(i = 0; i < n; i++)
			ptr[i] = model->probB[i];
	}
	else
		rhs[out_id] = mxCreateDoubleMatrix(0, 0, mxREAL);
	out_id++;

	// nSV
	if(model->nSV)
	{
		rhs[out_id] = mxCreateDoubleMatrix(model->nr_class, 1, mxREAL);
		ptr = mxGetPr(rhs[out_id]);
		for(i = 0; i < model->nr_class; i++)
			ptr[i] = model->nSV[i];
	}
	else
		rhs[out_id] = mxCreateDoubleMatrix(0, 0, mxREAL);
	out_id++;

	// sv_coef
	rhs[out_id] = mxCreateDoubleMatrix(model->l, model->nr_class-1, mxREAL);
	ptr = mxGetPr(rhs[out_id]);
	for(i = 0; i < model->nr_class-1; i++)
		for(j = 0; j < model->l; j++)
			ptr[(i*(model->l))+j] = model->sv_coef[i][j];
	out_id++;

	// SVs
	{
		int ir_index, nonzero_element;
		mwIndex *ir, *jc;
		mxArray *pprhs[1], *pplhs[1];	

		if(model->param.kernel_type == PRECOMPUTED)
		{
			nonzero_element = model->l;
			num_of_feature = 1;
		}
		else
		{
			nonzero_element = 0;
			for(i = 0; i < model->l; i++) {
				j = 0;
#ifdef _DENSE_REP
					nonzero_element+=model->SV[i].dim;
					j+=model->SV[i].dim;
#else
				while(model->SV[i][j].index != -1) 
				{
					nonzero_element++;
					j++;
				}
#endif
			}
		}

		// SV in column, easier accessing
		rhs[out_id] = mxCreateSparse(num_of_feature, model->l, nonzero_element, mxREAL);
		ir = mxGetIr(rhs[out_id]);
		jc = mxGetJc(rhs[out_id]);
		ptr = mxGetPr(rhs[out_id]);
		jc[0] = ir_index = 0;		
		for(i = 0;i < model->l; i++)
		{
			if(model->param.kernel_type == PRECOMPUTED)
			{
				// make a (1 x model->l) matrix
				ir[ir_index] = 0; 
#ifdef _DENSE_REP
				ptr[ir_index] = model->SV[i].values[0];
#else
				ptr[ir_index] = model->SV[i][0].value;
#endif
				ir_index++;
				jc[i+1] = jc[i] + 1;
			}
			else
			{
				int x_index = 0;
#ifdef _DENSE_REP
				while (x_index < model->SV[i].dim)
				{
					ir[ir_index] = x_index; 
					ptr[ir_index] = model->SV[i].values[x_index];
					ir_index++, x_index++;
				}
#else
				while (model->SV[i][x_index].index != -1)
				{
					ir[ir_index] = model->SV[i][x_index].index - 1; 
					ptr[ir_index] = model->SV[i][x_index].value;
					ir_index++, x_index++;
				}
#endif
				jc[i+1] = jc[i] + x_index;
			}
		}
		// transpose back to SV in row
		pprhs[0] = rhs[out_id];
		if(mexCallMATLAB(1, pplhs, 1, pprhs, "transpose"))
			return "cannot transpose SV matrix";
		rhs[out_id] = pplhs[0];
		out_id++;
	}

	/* Create a struct matrix contains NUM_OF_RETURN_FIELD fields */
	return_model = mxCreateStructMatrix(1, 1, NUM_OF_RETURN_FIELD, field_names);

	/* Fill struct matrix with input arguments */
	for(i = 0; i < NUM_OF_RETURN_FIELD; i++)
		mxSetField(return_model,0,field_names[i],mxDuplicateArray(rhs[i]));
	/* return */
	plhs[0] = return_model;
	mxFree(rhs);

	return NULL;
}

struct svm_model *matlab_matrix_to_model(const mxArray *matlab_struct, const char **msg)
{
	int i, j, n, num_of_fields;
	double *ptr;
	int id = 0;
#ifdef _DENSE_REP
	double *x_space;
#else
	struct svm_node *x_space;
#endif
	struct svm_model *model;
	mxArray **rhs;

	num_of_fields = mxGetNumberOfFields(matlab_struct);
	if(num_of_fields != NUM_OF_RETURN_FIELD) 
	{
		*msg = "number of return field is not correct";
		return NULL;
	}
	rhs = (mxArray **) mxMalloc(sizeof(mxArray *)*num_of_fields);

	for(i=0;i<num_of_fields;i++)
		rhs[i] = mxGetFieldByNumber(matlab_struct, 0, i);

	model = Malloc(struct svm_model, 1);
	model->rho = NULL;
	model->probA = NULL;
	model->probB = NULL;
	model->label = NULL;
	model->sv_indices = NULL;
	model->nSV = NULL;
	model->free_sv = 1; // XXX

	ptr = mxGetPr(rhs[id]);
	model->param.svm_type = (int)ptr[0];
	model->param.kernel_type  = (int)ptr[1];
	model->param.degree	  = (int)ptr[2];
	model->param.gamma	  = ptr[3];
	model->param.coef0	  = ptr[4];
	id++;

	ptr = mxGetPr(rhs[id]);
	model->nr_class = (int)ptr[0];
	id++;

	ptr = mxGetPr(rhs[id]);
	model->l = (int)ptr[0];
	id++;

	// rho
	n = model->nr_class * (model->nr_class-1)/2;
	model->rho = (double*) malloc(n*sizeof(double));
	ptr = mxGetPr(rhs[id]);
	for(i=0;i<n;i++)
		model->rho[i] = ptr[i];
	id++;

	// label
	if(mxIsEmpty(rhs[id]) == 0)
	{
		model->label = (int*) malloc(model->nr_class*sizeof(int));
		ptr = mxGetPr(rhs[id]);
		for(i=0;i<model->nr_class;i++)
			model->label[i] = (int)ptr[i];
	}
	id++;

	// sv_indices
	if(mxIsEmpty(rhs[id]) == 0)
	{
		model->sv_indices = (int*) malloc(model->l*sizeof(int));
		ptr = mxGetPr(rhs[id]);
		for(i=0;i<model->l;i++)
			model->sv_indices[i] = (int)ptr[i];
	}
	id++;

	// probA
	if(mxIsEmpty(rhs[id]) == 0)
	{
		model->probA = (double*) malloc(n*sizeof(double));
		ptr = mxGetPr(rhs[id]);
		for(i=0;i<n;i++)
			model->probA[i] = ptr[i];
	}
	id++;

	// probB
	if(mxIsEmpty(rhs[id]) == 0)
	{
		model->probB = (double*) malloc(n*sizeof(double));
		ptr = mxGetPr(rhs[id]);
		for(i=0;i<n;i++)
			model->probB[i] = ptr[i];
	}
	id++;

	// nSV
	if(mxIsEmpty(rhs[id]) == 0)
	{
		model->nSV = (int*) malloc(model->nr_class*sizeof(int));
		ptr = mxGetPr(rhs[id]);
		for(i=0;i<model->nr_class;i++)
			model->nSV[i] = (int)ptr[i];
	}
	id++;

	// sv_coef
	ptr = mxGetPr(rhs[id]);
	model->sv_coef = (double**) malloc((model->nr_class-1)*sizeof(double));
	for( i=0 ; i< model->nr_class -1 ; i++ )
		model->sv_coef[i] = (double*) malloc((model->l)*sizeof(double));
	for(i = 0; i < model->nr_class - 1; i++)
		for(j = 0; j < model->l; j++)
			model->sv_coef[i][j] = ptr[i*(model->l)+j];
	id++;

	// SV
	{
		int sr, sc, elements;
		int num_samples;
		mwIndex *ir, *jc;
		mxArray *pprhs[1], *pplhs[1];

		// transpose SV
		pprhs[0] = rhs[id];
		if(mexCallMATLAB(1, pplhs, 1, pprhs, "transpose")) 
		{
			svm_free_and_destroy_model(&model);
			*msg = "cannot transpose SV matrix";
			return NULL;
		}
		rhs[id] = pplhs[0];

		sr = (int)mxGetN(rhs[id]);
		sc = (int)mxGetM(rhs[id]);

		ptr = mxGetPr(rhs[id]);
		ir = mxGetIr(rhs[id]);
		jc = mxGetJc(rhs[id]);

		num_samples = (int)mxGetNzmax(rhs[id]);

		elements = num_samples + sr;

#ifdef _DENSE_REP
		model->SV = (struct svm_node *) malloc(sr * sizeof(struct svm_node));
		x_space = (double *)malloc(elements * sizeof(*x_space));
		memset(x_space, 0, elements * sizeof(*x_space));
#else
		model->SV = (struct svm_node **) malloc(sr * sizeof(struct svm_node *));
		x_space = (struct svm_node *)malloc(elements * sizeof(struct svm_node));
#endif

		// SV is in column
		for(i=0;i<sr;i++)
		{
			int low = (int)jc[i], high = (int)jc[i+1];
			int x_index = 0;
#ifdef _DENSE_REP
			model->SV[i].dim = sr;
			model->SV[i].values = &x_space[low+i];
#else
			model->SV[i] = &x_space[low+i];
#endif
			for(j=low;j<high;j++)
			{
#ifdef _DENSE_REP
				model->SV[i].values[(int)ir[j] + 1] = ptr[j];
#else
				model->SV[i][x_index].index = (int)ir[j] + 1; 
				model->SV[i][x_index].value = ptr[j];
#endif
				x_index++;
			}
#ifdef _DENSE_REP
#else
			model->SV[i][x_index].index = -1;
#endif
		}

		id++;
	}
	mxFree(rhs);

	return model;
}

void fill_field(mxArray *return_stat, const char *field_name, double field_value)
{
	mxArray *arr;
	double *ptr;
	arr = mxCreateDoubleMatrix(1, 1, mxREAL);
	ptr = mxGetPr(arr);
	ptr[0] = field_value;

	mxAddField(return_stat, field_name);
	mxSetField(return_stat, 0, field_name, arr);
}

mxArray *svm_train_stat_2_matlab(struct svm_train_stat *train_stat)
{
	/* Create a struct matrix contains NUM_OF_RETURN_FIELD fields */
	mxArray *return_stat = mxCreateStructMatrix(1, 1, 0, NULL);

	/* Fill struct */
	fill_field(return_stat, "IterationsNumber", train_stat->iter_num);
	fill_field(return_stat, "TrainTimeSeconds", train_stat->train_time_sec);
	fill_field(return_stat, "ModelsNumber", train_stat->models_num);

	return return_stat;
}
