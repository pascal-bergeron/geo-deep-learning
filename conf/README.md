## **Preparation of the `csv` file**
The `csv` file specifies the input images and the reference vectors data that will be use during the training, validation and testing phases.
Each row in the `csv` file must contain 5 comma-separated items for the five items that follow.
- path to the input image file (tif)
- (*Optional*) metadata info, leave empty if not desired. (see example below)
- path to the vectors data (GeoPackage)
- attribute of the GeoPackage to use as classes values
- where to use the dataset : '*trn*' for training, '*val*' for validation or '*tst*' for test  

Each image is a new line like:

```
\path\to\input\image1.tif,,\path\to\reference\vector1.gpkg,attribute,trn
\path\to\input\image2.tif,,\path\to\reference\vector2.gpkg,attribute,val
\path\to\input\image3.tif,,\path\to\reference\vector2.gpkg,attribute,tst
```
> **Note :** '*tst*' is optional for training the neural network, but if you want only use the inference, the code will only use the images from '*tst*'.

---

## **Preparation of the `yaml` file**
The `config_template.yaml` file located in the `conf` directory. We highly recommend to copy that file and past it inside a folder with all the information of the training (see the `Folder Structure` in the [README.md](../README.md#Folder-Structure) the main directory).

So this `yaml` file stores the values of all parameters needed by the deep learning algorithms for the three phases. The file contains the following sections:
* [Global](#Global)
* [Data Analysis](#Data-Analysis)
* [Sampling](#Sampling)
* [Training](#Training)
* [Inference](#Inference)
* [Visualization](#Visualisation)

<!-- Specific parameters in each section are shown below, where relevant. For more information about config.yaml, view file directly: [conf/config.yaml](https://github.com/NRCan/geo-deep-learning/blob/master/conf/config.yaml) -->

### **Global**
This section regroup all the general information and use by more that one sections.

```YAML
global:
  samples_size: 512
  num_classes: 5
  data_path: path/to/data
  number_of_bands: 4
  model_name: unet
  mlflow_uri: path/to/mlflow_tracking_uri
  bucket_name:
  task: segmentation
  num_gpus: 2
  BGR_to_RGB: True
  scale_data: [0,1]
  aux_vector_file:
  aux_vector_attrib:
  aux_vector_ids:
  aux_vector_dist_maps:
  aux_vector_dist_log:
  aux_vector_scale:
  debug_mode: True
  coordconv_convert: False
  coordvonc_scale:
```
- **`samples_size` :** Size of the tiles that you want to train/val/test with. We recommend `512` or `256` for the train/val task.

- **`num_classes` :** Number of classes that your *ground truth* have and which you want to predict at the end.

- **`data_path` :** Path to the folder where samples folder will be automatically created and all the other informations will be stored. **add the link to the example of stucture**

- **`number_of_bands` :** Number of bands in input images (RGB = 3 and RGBNir = 4).

- **`model_name` :** Name of the model use to train the neural network, see the list of all the implemented models in [`/models`](../models#Models-available).

- **`mlflow_uri` :** Path where *mlflow* will store all the informations about the runs. By default the path is `./mlruns`.

- **`bucket_name` (Optional) :** Name of the S3 bucket where the data is stored. Leave blank if using local files.

- **`task` :** Task to perform, either segmentation or classification, but classification is no longer supported.

- **`num_gpus` :** Number of **GPUs** that you want to use, `0` will use the **CPU**.

- **`BGR_to_RGB` :** **TODO**

- **`scale_data` :** Min and Max for input data rescaling, by default: `[0, 1]` meaning no rescaling.

- **`aux_vector_file` :** **TODO**

- **`aux_vector_attrib` :** **TODO**

- **`aux_vector_ids` :** **TODO**

- **`aux_vector_dist_maps` :** **TODO**

- **`aux_vector_dist_log` :** **TODO**

- **`aux_vector_scale` :** **TODO**

- **`debug_mode` :** Activates various debug features for example, details about intermediate outputs, detailed progress bars, etc. By default this mode is `False`.

- **`coordconv_convert` :** **TODO** False

- **`coordvonc_scale` :** **TODO**

### **Data Analysis**
The [data_analysis](data_analysis.py) module is used to visualize the composition of the sample's classes and see how it shapes the training dataset and can be  useful for balancing training data in which a class is under-represented. Using basic statistical analysis, the user can test multiple sampling parameters and immediately see their impact on the classes' distribution. It can also be used to automatically search optimal sampling parameters and obtain a more balanced class distribution in the dataset.

The sampling parameters can then be used in [images_to_samples.py](../images_to_samples.py) to obtain the desired dataset or can be use alone this way there is no need to run the full code to find out how the classes are distributed (see the [example](#Running)).

Before running [data_analysis.py](data_analysis.py), the paths to the `csv` file containing all the information about the images and the data folder must be specified in the `yaml` file use to the experience.
```YAML
# Global parameters
global:
  samples_size: 512
  num_classes: 5
  data_path: path/to/data                 # <--- must be specified
  number_of_bands: 4

      ...

# Sample parameters; used in images_to_samples.py -------------------
sample:
  prep_csv_file: /path/to/csv/images.csv  # <--- must be specified
  val_percent: 5

```

Here is an example of the data_analysis section in the `YAML` file :

```YAML
data_analysis:
  create_csv: True
  optimal_parameters_search : False
  sampling_method: # class_proportion or min_annotated_percent
    'min_annotated_percent': 0  # Min % of non background pixels in samples.
    'class_proportion': {'1':0, '2':0, '3':0, '4':0} # See below:
    # keys (numerical values in 'string' format) represent class id
    # values (int) represent class minimum threshold targeted in samples
```
- **`create_csv` :**
This parameter is used to create a `csv` file containing the class proportion data of each image sample. This first step is mandatory to ensure the proper operation of the module. Once it is created, the same `csv` file is used for every tests the user wants to perform. Once that is done, the parameter can then be changed to `False`.
This parameter would have to be changed to `True` again if any changes were made to the content of the `prep_csv_file` or if the user wishes to change the values of the `samples_size` parameters. These parameters have a direct effect on the class proportion calculation. The `csv` file created is stored in the folder specified in the `data_path` of the global section.

- **`optimal_parameters_search` :**
When this parameter is set to `True`, it activates the optimal sampling parameters search function. This function aims to find which sampling parameters produce the most balanced dataset based on the standard deviation between the proportions of each class in the dataset. The sampling method(s) used for the search function must first be specified in the `sampling_method` dictionary in the `data_analysis` section. It does not take into account the values of the other keys in the dictionary. The function first returns the optimal threshold(s) for the chosen sampling method(s). It then returns a preview of the proportions of each classes and the size of the final dataset without creating it, like the following image.
<p align="center">
   <img align="center" src="/docs/screenshots/stats_parameters_search_map_cp.PNG">
</p>

- **`sampling_method` :**
For `min_annotated_percent` is the minimum percent of non background pixels in the samples. By default the value is `0` and the targeted minimum annotated percent must by a integer.
`class_proportion` should be a dictionary with the number of each classes in the images in quotes. Specify the minimum class proportion of one or all classes with integer(s) or float(s). Example, `'0':0, '1':10, '2':5, '3':5, ...`
<!-- `min_annotated_percent`, For this value to be taken into account, the `optimal_paramters_search` function must be turned off and 'min_annotated_percent' must be listed in the `'method'` key of the `sampling` dictionary. -->
<!-- `class_proportion`, For these values to be taken into account, the `optimal_paramters_search` function must be turned off and 'class_proportion' must be listed in the `'method'` key of the `sampling` dictionary. -->

###### Running [data_analysis.py](data_analysis.py)
You can run the data analysis alone if you only want the stats, and to do that you only need to launch the program :
```shell
python data_analysis.py path/to/yaml_files/your_config.yaml
```

### **Sampling**
This section is use by [images_to_samples.py](../images_to_samples.py) to prepare the images for the training, validation and inference. Those images must be geotiff combine with a GeoPackage, otherwise it will not work.

In addition, [images_to_samples.py](../images_to_samples.py) will assert that all geometries for features in GeoPackages are valid according to [Rasterio's algorithm](https://github.com/mapbox/rasterio/blob/d4e13f4ba43d0f686b6f4eaa796562a8a4c7e1ee/rasterio/features.py#L461).

```yaml
sample:
  prep_csv_file: path/to/images.csv
  val_percent: 5
  overlap: 25
  sampling_method:
    'min_annotated_percent': 0
    'class_proportion': {'1':0, '2':0, '3':0, '4':0}
  mask_reference: False
```
- **`prep_csv_file` :** Path to your `csv` file with the information on the images.

- **`val_percent` :** Percentage of validation samples created from train set (0 - 100), we recommend at least `5`, must be an integer (int).

- **`overlap` :** Percentage of overlap between 2 chunks, must be an integer (int).

- **`sampling_method` :**
  - `min_annotated_percent` is the percentage minimum of non background pixels in samples by default we chose `0`, must be an integer (int).
  - `class_proportion` is a dictionary (dict) where the keys (numerical values in 'string' format) represent class id and the values (int) represent the class minimum threshold targeted in samples. An example of four classes with no minimum: `{'1':0, '2':0, '3':0, '4':0}`.

- **`mask_reference` :** A mask that mask the input image where there is no reference data, when the value is `True`.

###### Running [images_to_samples.py](../images_to_samples.py)
You must run this code before training to generate the `hdf5` use by the other code.
Even if you only want to do inference on the images, you need to generate a `tst_samples.hdf5`.

To launch the code:
```shell
python images_to_samples.py path/to/yaml_files/your_config.yaml
```
The output of this code will result at the following structure:
```
├── {data_path}
    └── {samples_folder}
        └── trn_samples.hdf5
        └── val_samples.hdf5
        └── tst_samples.hdf5
```
The name of the `{samples_folder}` will be written by the informations chosen like :
`samples{samples_size}_overlap{overlap}_min-annot{min_annot_perc}_{num_bands}bands`

>If folder already exists, a suffix with `_YYYY-MM-DD_HH-MM` will be added

### **Training**



---

## images_to_samples.py

Details on parameters used by this module:

```yaml
global:
  samples_size: 256         # Size (in pixel) of the samples.
  num_classes: 2            # Number of classes.
  data_path: /path/to/data  # Path to folder where samples folder will be automatically created
  number_of_bands: 3        # Number of bands in input images.
  model_name: unetsmall     # One of unet, unetsmall, checkpointed_unet, ternausnet, or inception
  bucket_name:              # name of the S3 bucket where data is stored. Leave blank if using local files
  scale_data: [0, 1]        # Min and Max for input data rescaling. Default: [0, 1]. Default: No rescaling
  debug_mode: True          # Activates various debug features (ex.: details about intermediate outputs, detailled progress bars, etc.). Default: False

sample:
  prep_csv_file: /path/to/file_name.csv  # Path to CSV file used in preparation.
  overlap: 200                           # (int) Percentage of overlap between 2 samples. Mandatory
  val_percent: 5                         # Percentage of validation samples created from train set (0 - 100)
  min_annotated_percent: 10              # Min % of non background pixels in stored samples. Mandatory
  mask_reference: False                  # When True, mask the input image where there is no reference data.
```

### Process
1. Read csv file and validate existence of all input files and GeoPackages.
2. Do the following verifications:
    1. Assert number of bands found in raster is equal to desired number of bands
    2. Check that `num_classes` is equal to number of classes detected in the specified attribute for each GeoPackage. Warning: this validation **will not succeed** if a Geopackage contains only a subset of `num_classes` (e.g. 3 of 4).
    3. Assert Coordinate reference system between raster and gpkg match.
3. Read csv file and for each line in the file, do the following:
    1. Read input image as array with `utils.readers.image_reader_as_array()`.
        - If gpkg's extent is smaller than raster's extent, raster is clipped to gpkg's extent.
        - If gpkg's extent is bigger than raster's extent, gpkg is clipped to raster's extent.
    2. Convert GeoPackage vector information into the "label" raster with `utils.utils.vector_to_raster()`. The pixel value is determined by the attribute in the csv file.
    3. Create a new raster called "label" with the same properties as the input image
    4. Read metadata and add to input as new bands (*more details to come*)
    5. Crop arrays in smaller samples of size `samples_size` and distance `num_classes` specified in the configuration file. Visual representation of this is provided [here](https://medium.com/the-downlinq/broad-area-satellite-imagery-semantic-segmentation-basiss-4a7ea2c8466f)
    6. Write samples from input image and label into the "val", "trn" or "tst" hdf5 file, depending on the value contained in the csv file. Refer to `samples_preparation()`.



### Debug mode
- Images_to_samples.py will assert that all geometries for features in GeoPackages are valid according to [Rasterio's algorithm](https://github.com/mapbox/rasterio/blob/d4e13f4ba43d0f686b6f4eaa796562a8a4c7e1ee/rasterio/features.py#L461).   

## train_segmentation.py

The crux of the learning process is in this phase : training.  
- Samples labeled "trn" as per above are used to train the neural network.
- Samples labeled "val" are used to estimate the training error (i.e. loss) on a set of sub-images not used for training, after every epoch.
- At the end of all epochs, the model with the lowest error on validation data is loaded and samples labeled "tst", if they exist, are used to estimate the accuracy of the model on sub-images unseen during training or validation.

To launch the program:
```
python train_segmentation.py path/to/config/file/config.yaml
```
Details on parameters used by this module:
```yaml
global:
  samples_size: 256          # Size (in pixel) of the samples
  num_classes: 2             # Number of classes
  data_path: /path/to/data   # Path to folder containing samples folder. Model and log files will be written in samples folder
  number_of_bands: 3         # Number of bands in input images
  model_name: unetsmall      # One of unet, unetsmall, checkpointed_unet, ternausnet, or inception
  bucket_name:               # name of the S3 bucket where data is stored. Leave blank if using local files
  task: segmentation         # Task to perform. Either segmentation or classification
  num_gpus: 0                # Number of GPU device(s) to use. Default: 0
  debug_mode: True           # Activates various debug features (ex.: details about intermediate outputs, detailled progress bars, etc.). Default: False

sample:
  overlap: 20                # % of overlap between 2 samples Note: high overlap > 25 creates very similar samples between train and val sets.   
  min_annotated_percent: 10  # Min % of non background pixels in stored samples.

training:
  state_dict_path: /path/to/checkpoint.pth.tar  # path to checkpoint from trained model as .pth.tar or .pth file. Optional.
  pretrained: True           # if True, pretrained model will be loaded if available (e.g. Deeplabv3 pretrained on coco dataset). Default: True if no state_dict is given
  num_trn_samples: 4960      # Number of samples to use for training. (default: all samples in hdfs file are taken)
  num_val_samples: 2208      # Number of samples to use for validation. (default: all samples in hdfs file are taken)
  num_tst_samples:           # Number of samples to use for test. (default: all samples in hdfs file are taken)
  batch_size: 32             # Size of each batch
  num_epochs: 150            # Number of epochs
  loss_fn: Lovasz            # One of CrossEntropy, Lovasz, Focal, OhemCrossEntropy (*Lovasz for segmentation tasks only)
  optimizer: adabound        # One of adam, sgd or adabound
  learning_rate: 0.0001      # Initial learning rate
  weight_decay: 0            # Value for weight decay (each epoch)
  step_size: 4               # Apply gamma every step_size
  gamma: 0.9                 # Multiple for learning rate decay
  dropout: False             # (bool) Use dropout or not. Applies to certain models only.
  dropout_prob: False        # (float) Set dropout probability, e.g. 0.5
  class_weights: [1.0, 2.0]  # Weights to apply to each class. A value > 1.0 will apply more weights to the learning of the class. Applies to certain loss functions only.
  batch_metrics: 2           # (int) Metrics computed every (int) batches. If left blank, will not perform metrics. If (int)=1, metrics computed on all batches.
  ignore_index: 0            # Specifies a target value that is ignored and does not contribute to the input gradient. Default: None
```

### Inputs
- samples folder as created by `images_to_samples.py` (See: [Images_to_samples.py / Outputs](#samples_outputs)) containing:
    - `trn_samples.hdf5`, `val_samples.hdf5`, `tst_samples.hdf5`. Each hdf5 file contains input images and reference data as arrays used for training, validation and test, respectively.

#### Augmentations

Details on parameters used by this module:
```yaml  
training:
   augmentation:
        rotate_limit: 45         # Specifies the upper and lower limits for data rotation. If not specified, no rotation will be performed.
        rotate_prob: 0.5         # Specifies the probability for data rotation. If not specified, no rotation will be performed.
        hflip_prob: 0.5          # Specifies the probability for data horizontal flip. If not specified, no horizontal flip will be performed.    
        random_radiom_trim_range: [0.1, 2.0] # Specifies the range in which a random percentile value will be chosen to trim values. This value applies to both left and right sides of the raster's histogram. If not specified, no enhancement will be performed.
        geom_scale_range:        # Not yet implemented
        noise:                   # Not yet implemented
```
These augmentations are a [common procedure in machine learning](https://www.coursera.org/lecture/convolutional-neural-networks/data-augmentation-AYzbX). More augmentations could be implemented in a near. See issue [#106](https://github.com/NRCan/geo-deep-learning/issues/106).

Note: For specific details about implementation of these augmentations, check docstrings in utils.augmentation.py.

Warning:
- RandomCrop is used only if parameter `target_size` (in training section of config file) is not empty. Also, if this parameter is omitted, the hdf5 samples will be fed as is to the model in training (after other augmentations, if applicable). This can have an major impact on GPU RAM used and could cause `CUDA: Out of memory errors`.  

### Process
1. Model is instantiated and checkpoint is loaded from path, if provided in `config.yaml`.
2. GPUs are requested according to desired amount of `num_gpus` and available GPUs.
3. If more than 1 GPU is requested, model is casted to [`DataParallel`](https://pytorch.org/tutorials/beginner/blitz/data_parallel_tutorial.html) model
4. Dataloaders are created with `create_dataloader()`
5. Loss criterion, optimizer and learning rate are set with `set_hyperparameters()` as requested in `config.yaml`.
5. Using these hyperparameters, the application will try to minimize the loss on the training data and evaluate every epoch on the validation data.
6. For every epoch, the application shows and logs the loss on "trn" and "val" datasets.
7. For every epoch (if `batch_metrics: 1`), the application shows and logs the accuracy, recall and f-score on "val" dataset. Those metrics are also computed on each classes.  
8. At the end of the training process, the application shows and logs the accuracy, recall and f-score on "tst" dataset. Those metrics are also computed on each classes.

### <a name="training_outputs"></a> Output
- Trained model weights as `checkpoint.pth.tar`. Corresponding to the training state where the validation loss was the lowest during the training process.

```
├── {data_path}
    └── {samples_folder} (See: images_to_samples.py / Outputs)
        └── model
            └── {model_name}*
                └── checkpoint.pth.tar
                └── {log files}
                └── copy of config.yaml (automatic)
```
*{model_name} is set from yaml name. Therefore, **yaml name should be relevant and unique**. If folder already exists, a suffix with `_YYYY-MM-DD_HH-MM` is added.

### Loss functions
- Cross-Entropy (standard loss functions as implemented in [torch.nn](https://pytorch.org/docs/stable/_modules/torch/nn/modules/loss.html))
- [Multi-class Lovasz-Softmax loss](https://arxiv.org/abs/1705.08790)
- Ohem Cross Entropy. Adapted from [OCNet Repository](https://github.com/PkuRainBow/OCNet)
- [Focal Loss](https://www.kaggle.com/c/tgs-salt-identification-challenge/discussion/65938)

### Optimizers
- Adam (standard optimizer in [torch.optim](https://pytorch.org/docs/stable/optim.html))
- SGD (standard optimizer in [torch.optim](https://pytorch.org/docs/stable/optim.html)
- [Adabound/AdaboundW](https://openreview.net/forum?id=Bkg3g2R9FX)

### Debug mode
- During training, `train_segmentation.py` will display in progress bar:
    - train loss for last batch
    - GPUs usage (% and RAM)
    - current learning rate
    - input image shape
    - label shape
    - batch size
    - number of predicted classes in each output array (if only one predicted class, there's a problem!)   

### Advanced features
- To check how a trained model performs on test split without fine-tuning, simply:
    1. Specify `training` / `state_dict_path` for this model in `config.yaml`
    2. In same parameter section, set `num_epochs` to 0. The execution will then jump right away to `evaluation` on test set with loaded model without training.

## inference.py

The final step in the process is to assign every pixel in the original image a value corresponding to the most probable class.

To launch the program:
```
python inference.py path/to/config/file/config.yaml
```

Details on parameters used by this module:
```yaml
global:
  number_of_bands: 3        # Number of bands in input images
  model_name: unetsmall     # One of unet, unetsmall, checkpointed_unet, ternausnet, or inception
  bucket_name:              # name of the S3 bucket where data is stored. Leave blank if using local files
  task: segmentation        # Task to perform. Either segmentation or classification
  scale_data: [0, 1]        # Min and Max for input data rescaling. Default: [0, 1]. Enter False if no rescaling is desired.
  debug_mode: True          # Prints detailed progress bar


inference:
  img_dir_or_csv_file: /path/to/list.csv        # CSV file containing directory of images with or without gpkg labels(used in benchmarking)
  working_folder: /path/to/output_images        # Folder where all resulting images will be written (DEPRECATED, leave blank)
  state_dict_path: /path/to/checkpoint.pth.tar  # Path to model weights for inference
  chunk_size: 512                               # (int) Size (height and width) of each prediction patch. Default: 512
  smooth_prediction: True                       # Smoothening Predictions with 2D interpolation
  overlap: 2                                    # overlap between tiles for smoothing. Must be an even number that divides chunk_size without remainder.
```
### Process
- The process will load trained weights to the chosen model and perform a per-pixel inference task on all the images contained in the working_folder

### Outputs
- one .tif per input image. Output file has same dimensions as input and georeference.
- Structure:
```
├── {state_dict_path}
    └── checkpoint.pth.tar (used for inference)
    └── inference_{num_bands}
        └── {.tifs from inference}
```

### Debug mode
- During inference, visualization is performed for each inferred chunk
- Detailled progress bar with:
    - GPUs usage (% and RAM)
    - input chunk shape
    - output shape
    - overlay between chunks  
- output_counts.png is saved. Let's user see regions were multiple inferences are done.

## Visualization

Details on parameters used by this module:
```yaml
visualization:
  vis_batch_range: [0,200,10] #first batch to visualize on, last batch (excluded), increment. If empty, no visualization will be performed no matter the value of other parameters.
  vis_at_checkpoint: True     # Visualize samples every time a checkpoint is saved
  vis_at_ckpt_min_ep_diff: 0  # Define minimum number of epoch that must separate two checkpoints in order to visualize at checkpoint
  vis_at_ckpt_dataset: val    # define dataset to be used for vis_at_checkpoint. Default: 'val'
  vis_at_init: True           # Visualize samples with instantiated model before first epoch
  vis_at_init_dataset: val    # define dataset to be used for vis_at_init. Default: 'val'
  vis_at_evaluation: True     # Visualize samples val during evaluation, 'val' during training, 'tst' at end of training
  vis_at_train: True          # Visualize on training samples during training
  grid: True                  # Save visualization outputs as a grid. If false, each image is saved as separate .png. Default: False
  heatmaps: True              # Also save heatmaps (activation maps) for each class as given by model before argmax.
  colormap_file: ./data/colormap.csv # Custom colormap to define custom class names and colors for visualization. Optional
```

### Colormap

All visualization functions use a colormap for two main purposes:
1. Assign colors to grayscale outputs (as outputted by pytorch) and labels, if given (i.e. not during inference).

2. Assign a name to each heatmap. This name is displayed above heatmap in grid if `grid: True`. Otherwise, each heatmap is saved as a .png. Class name is then added in the name of .png.
If left empty, a default colormap is used and integers are assigned for each class in output.  

If desired, the user can therefore specify a path to a custom colormap with the `colormap_file` parameter in the `config.yaml`.
The custom colormap must be a .csv with 3 columns, as shown below. One line is added for each desired class.

Input value|Class name|Html color
:---:|:---:|:---:
1|vegetation|#00680d
2|hydro|#b2e0e6
3|roads|#990000
4|buildings|#efcd08   

### Process and Outputs
Visualization is called in three main functions:
1. `vis_from_dataloader()`: iterates through a provided dataloader and sends batch outputs, along with inputs and labels to `vis_from_batch()`. Is used when parameters `vis_at_checkpoint` or `vis_at_init` is `True`
2. `vis_from_batch()`: iterates though items of a batch and sends them to `vis()`
3. `vis()`:
    1. converts input to 8bit image if scaling had been performed during training (e.g. scaling between 0 and 1).
    2. iterates through channels of output to extract each heatmap (i.e. activation map)
    3. builds dictionary with heatmap where key is grayscale value and value is `{'class_name': 'name_of_class', 'heatmap_PIL': heatmap_as_PIL_Image}`
    4. saves 8bit input, color output and color label (if given) as .png in a grid or as individual pngs.

The `vis_batch_range` parameter plays a central role in visualization. First number in list is first batch to visualize on. Second number is last batch (excluded) from which no more visualization is done. Last number in list is increment in batch index. For example, if `vis_batch_range = [10,20,2]`, visualization will occur (as requested by other visualization parameters) on batches 10, 12, 14, 16 et 18. **If `vis_batch_range` is left empty, no visualization will be performed no matter the value of other parameters.**

> Outputs are sent to visualization functions immediately after line `outputs = model(inputs)`, i.e. before `argmax()` function is used to flatten outputs and keep only value to most probable class, pixel-wise.

> During inference, visualization functions are also called, but instead of outputting .pngs, `vis()` outputs a georeferenced .tif. Heatmaps, if `inference`/`heatmaps` is `True`, are also saved as georeferenced .tifs, in grayscale format (i.e. single band).

### Debug mode
- if in inference, `vis()` will print all unique values in each heatmap array. If there are only a few values, it gives a hint on usefulness of heatmap.
- if in inference, `vis()` will check number of predicted classes in output array. If only one predicted class, a warning is sent.


---

Structure as created by geo-deep-learning
```
├── {data_path}
    └── {samples_folder}*
        └── trn_samples.hdf5
        └── val_samples.hdf5
        └── tst_samples.hdf5
        └── model
            └── {model_name}**
                └── checkpoint.pth.tar
                └── {log files}
                └── copy of config.yaml (automatic)
                └── visualization
                    └── {.pngs from visualization}
                └── inference
                    └── {.tifs from inference}
```