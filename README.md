# MATLAB Glioma Classifier


## CITS4402 - Computer Vision - Project, Semester 1 2024. 

**Developed By:**
- [Mitchell Otley](https://github.com/just1mitch)
- [Nate Trew](https://github.com/Nate202003)
- [James Wigfield](https://github.com/JamesW293)

MATLAB Application designed to apply Computer Vision techniques to a dataset of Magnetic Resonance Imaging (MRI) scans, to diagnose Glioma as either Low-Grade Glioma (LGG) or High-Grade Glioma (HGG). The application provides the functionality of dynamically visualising the MRI and performing large-scale data analysis of a dataset of MRIs.

Feature Detection and Extraction of both conventional features (Tumor area and diameter, Outer Layer Involvement) and radiomic features (Intensity, Shape and Texture features) are available.

MATLAB's Classification Learner App is used to develop a Support Vector Machine (SVM). Using data extracted from 359 MRI scans, we developed a model that was capable of diagnosing LGG or HGG with an accuracy of 80.3%.

To run the application, run GUI.m in MATLAB (Developed with MATLAB R2023b). To see a detailed breakdown of the feature detection, extraction and SVM training process, see our [write-up](https://github.com/just1mitch/glioma-classification/blob/main/readme_svm.pdf).


[Dataset retrieved from Kaggle](https://www.kaggle.com/datasets/awsaf49/brats2020-training-data/data)

## Application Preview
| ![application](https://github.com/just1mitch/glioma-classification/assets/57031880/22efa93c-33cf-4e18-8c12-22c6651f0a8e) | 
|:--:| 
| *MATLAB Application* |

| ![application](https://github.com/just1mitch/glioma-classification/assets/57031880/c4fa449e-7ff8-475f-8a9f-ab0889ac9b40) | 
|:--:| 
| *SVM Classifier* |




