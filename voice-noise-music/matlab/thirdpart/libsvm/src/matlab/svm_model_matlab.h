#ifndef SVM_MODEL_MATLAB_H
#define SVM_MODEL_MATLAB_H

#include <svm.h>

const char *model_to_matlab_structure(mxArray *plhs[], int num_of_feature, struct svm_model *model);
struct svm_model *matlab_matrix_to_model(const mxArray *matlab_struct, const char **error_message);

struct mxArray *svm_train_stat_2_matlab(struct svm_train_stat *train_stat);

#endif // SVM_MODEL_MATLAB_H
