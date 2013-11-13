#include <fstream>
#include <sstream>
#include <vector>
#include <cstring>
#include <cstdlib>

#include "svms.h"

class tokenizer_string {
	std::vector<char> data;
	size_t tok_pos;

public:
	void set_str(const std::string &str) {
		data.assign(str.begin(), str.end());
		data.push_back(0);
		tok_pos=0;
	}

	const char * c_str() const {
		return &data[0];
	}

	const char * get_next_token(const char *delim_chars) {
		if(tok_pos>=data.size()-1)
			return NULL;
		tok_pos+=strspn(&data[tok_pos], delim_chars);
		if(tok_pos==data.size()-1)
			return NULL;
		const char *ret=&data[tok_pos];
		tok_pos+=strcspn(ret, delim_chars);
		data[tok_pos++]=0;
		return ret;
	}
};

#define Malloc(type,n) (type *)malloc((n)*sizeof(type))

// static char *line = NULL;
// static int max_line_len;

static const char *svm_type_table[] =
{
	"c_svc","nu_svc","one_class","epsilon_svr","nu_svr",NULL
};

static const char *kernel_type_table[]=
{
	"linear","polynomial","rbf","sigmoid","precomputed",NULL
};

bool readline(std::istream& file, tokenizer_string &line_tok)
{
	if(file.tellg()==std::istream::pos_type(-1))
		return false;

	std::string line;
	do {
		std::getline(file, line);

		if(file.tellg()==std::istream::pos_type(-1))
			return false;
	} while(line.empty());

	line_tok.set_str(line);

	return true;
}

svm_model *svm_load_model_from_string(const char *model_content)
{
	std::stringstream file(model_content);
	return svm_load_model_from_stream(file);
}

svm_model *svm_load_model_from_file(const char *model_file_name)
{
	std::fstream file(model_file_name);
	return svm_load_model_from_stream(file);
}
svm_model *svm_load_model_from_stream(std::istream& file)
{
	if(!file) return NULL;

//	file.imbue(std::locale::classic()); //@@@ Это почему-то не работает, хотя именно это правильный вариант

	char *old_locale = strdup(setlocale(LC_ALL, NULL));
	setlocale(LC_ALL, "C");

	// read parameters

	svm_model *model = Malloc(svm_model,1);
	svm_parameter& param = model->param;
	model->rho = NULL;
	model->probA = NULL;
	model->probB = NULL;
	model->label = NULL;
	model->nSV = NULL;

	char cmd[81];
	while(1)
	{
		file >> cmd;

		if(strcmp(cmd,"svm_type")==0)
		{
			file >> cmd;

			int i;
			for(i=0;svm_type_table[i];i++)
			{
				if(strcmp(svm_type_table[i],cmd)==0)
				{
					param.svm_type=i;
					break;
				}
			}
			if(svm_type_table[i] == NULL)
			{
				fprintf(stderr,"unknown svm type.\n");

				setlocale(LC_ALL, old_locale);
				free(old_locale);
				free(model->rho);
				free(model->label);
				free(model->nSV);
				free(model);
				return NULL;
			}
		}
		else if(strcmp(cmd,"kernel_type")==0)
		{
			file >> cmd;
			int i;
			for(i=0;kernel_type_table[i];i++)
			{
				if(strcmp(kernel_type_table[i],cmd)==0)
				{
					param.kernel_type=i;
					break;
				}
			}
			if(kernel_type_table[i] == NULL)
			{
				fprintf(stderr,"unknown kernel function.\n");

				setlocale(LC_ALL, old_locale);
				free(old_locale);
				free(model->rho);
				free(model->label);
				free(model->nSV);
				free(model);
				return NULL;
			}
		}
		else if(strcmp(cmd,"degree")==0)
			file >> param.degree;
		else if(strcmp(cmd,"gamma")==0)
			file >> param.gamma;
		else if(strcmp(cmd,"coef0")==0)
			file >> param.coef0;
		else if(strcmp(cmd,"nr_class")==0)
			file >> model->nr_class;
		else if(strcmp(cmd,"total_sv")==0)
			file >> model->l;
		else if(strcmp(cmd,"rho")==0)
		{
			int n = model->nr_class * (model->nr_class-1)/2;
			model->rho = Malloc(double,n);
			for(int i=0;i<n;i++)
				file >> model->rho[i];
		}
		else if(strcmp(cmd,"label")==0)
		{
			int n = model->nr_class;
			model->label = Malloc(int,n);
			for(int i=0;i<n;i++)
				file >> model->label[i];
		}
		else if(strcmp(cmd,"probA")==0)
		{
			int n = model->nr_class * (model->nr_class-1)/2;
			model->probA = Malloc(double,n);
			for(int i=0;i<n;i++)
				file >> model->probA[i];
		}
		else if(strcmp(cmd,"probB")==0)
		{
			int n = model->nr_class * (model->nr_class-1)/2;
			model->probB = Malloc(double,n);
			for(int i=0;i<n;i++)
				file >> model->probB[i];
		}
		else if(strcmp(cmd,"nr_sv")==0)
		{
			int n = model->nr_class;
			model->nSV = Malloc(int,n);
			for(int i=0;i<n;i++)
				file >> model->nSV[i];
		}
		else if(strcmp(cmd,"SV")==0)
		{
			while(1)
			{
				file.read(cmd, 1);
				if(cmd[0]==EOF || cmd[0]=='\n') break;
			}
			break;
		}
		else
		{
			fprintf(stderr,"unknown text in model file: [%s]\n",cmd);

			setlocale(LC_ALL, old_locale);
			free(old_locale);
			free(model->rho);
			free(model->label);
			free(model->nSV);
			free(model);
			return NULL;
		}
	}

	// read sv_coef and SV

	int elements = 0;
	std::istream::pos_type pos = file.tellg();

	tokenizer_string line_str;

#ifdef _DENSE_REP
	int max_index = 1;
	// read the max dimension of all vectors
	while(readline(file, line_str))
	{
		const char *line_ptr=line_str.c_str();
		const char *p = strrchr(line_ptr, ':');
		char *endptr;
		if(p != NULL)
		{
			while(*p != ' ' && *p != '\t' && p > line_ptr)
				p--;
			if(p > line_ptr)
				max_index = (int) strtol(p,&endptr,10) + 1;
		}
		if(max_index > elements)
			elements = max_index;
	}
#else
	while(readline(file, line_str))
	{
		const char *p = line_str.get_next_token(":");
		while(1)
		{
			p = line_str.get_next_token(":");
			if(p == NULL)
				break;
			++elements;
		}
	}
	elements += model->l;
#endif

	file.clear();
	file.seekg(pos);

	int m = model->nr_class - 1;
	int l = model->l;
	model->sv_coef = Malloc(double *,m);
	int i;
	for(i=0;i<m;i++)
		model->sv_coef[i] = Malloc(double,l);

#ifdef _DENSE_REP
	int index;
	model->SV = Malloc(svm_node,l);

	for(i=0;i<l;i++)
	{
		readline(file, line_str);

		model->SV[i].values = Malloc(double, elements);
		model->SV[i].dim = 0;

		const char *p = line_str.get_next_token(" \t");
		char *endptr;
		model->sv_coef[0][i] = strtod(p,&endptr);
		for(int k=1;k<m;k++)
		{
			p = line_str.get_next_token(" \t");
			model->sv_coef[k][i] = strtod(p,&endptr);
		}

		int *d = &(model->SV[i].dim);
		while(1)
		{
			const char * idx = line_str.get_next_token(":");
			const char * val = line_str.get_next_token(" \t");

			if(val == NULL)
				break;
			index = (int) strtol(idx,&endptr,10)-1; // @ DAG 2013/05/27: Fix dense mode 1-based indexing
			while (*d < index)
				model->SV[i].values[(*d)++] = 0.0;
			model->SV[i].values[(*d)++] = strtod(val,&endptr);
		}
	}
#else
	model->SV = Malloc(svm_node*,l);
	svm_node *x_space = NULL;
	if(l>0) x_space = Malloc(svm_node,elements);

	int j=0;
	for(i=0;i<l;i++)
	{
		readline(file, line_str);
		model->SV[i] = &x_space[j];

		const char *p = line_str.get_next_token(" \t");
		char *endptr;
		model->sv_coef[0][i] = strtod(p,&endptr);
		for(int k=1;k<m;k++)
		{
			p = line_str.get_next_token(" \t");
			model->sv_coef[k][i] = strtod(p,&endptr);
		}

		while(1)
		{
			const char *idx = line_str.get_next_token(":");
			const char *val = line_str.get_next_token(" \t");

			if(val == NULL)
				break;
			x_space[j].index = (int) strtol(idx,&endptr,10);
			x_space[j].value = strtod(val,&endptr);

			++j;
		}
		x_space[j++].index = -1;
	}
#endif

	setlocale(LC_ALL, old_locale);
	free(old_locale);

	model->free_sv = 1;	// XXX
	return model;
}
