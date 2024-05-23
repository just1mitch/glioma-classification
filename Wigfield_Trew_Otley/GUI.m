classdef gliomaApp_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        ExtractRadiomicFeaturesButton  matlab.ui.control.Button
        ExtractConventionalFeaturesButton  matlab.ui.control.Button
        ToggleTumorMaskSwitch          matlab.ui.control.Switch
        ToggleTumorMaskSwitchLabel     matlab.ui.control.Label
        Label                          matlab.ui.control.Label
        ImageAcquisitionProtocolButtonGroup  matlab.ui.container.ButtonGroup
        T2Button                       matlab.ui.control.ToggleButton
        T2FLAIRButton                  matlab.ui.control.ToggleButton
        T1GdButton                     matlab.ui.control.ToggleButton
        T1Button                       matlab.ui.control.ToggleButton
        SliceSlider                    matlab.ui.control.Slider
        BrowseButton                   matlab.ui.control.Button
        UITable                        matlab.ui.control.Table
    end

    
    properties (Access = private)
        center;                   % Center of screen for image
        directory;                % Directory path containing .h5 files
        filedata;                 % List of filedata
        mri_axes;                 % Axes displaying the MRI
        slice_images;             % Slice image data from .h5 files - 155x4x240x240
        slice_masks;              % Slice mask data from .h5 files - 155x3x240x240
        slice_shown;              % Index of the currently shown slice
        slice_masks_conventional; %for conventional data 
        slice_images_conventional;%for conventional data 
        conventional_data_arr;    %array to store all conventiona data
        conventional_dir          % directory path convnetional features analysed from
        mri_image;                % Image data currently being displayed - 240x240x3
        protocol;                 % Currently selected image acquisition protocol
        protocol_enum;            % Enumeration set at startup of protocol name to slice index
        mask_status;              % Boolean - true if tumor mask is on, false if off
        shape_fnames;             % Cell array of the 10 selected shape features - 1x10
        intensity_fnames;         % Cell array of the 10 selected intensity features - 1x10
        texture_fnames;           % Cell array of the 10 selected texture features - 1x10
    end
    
    methods (Access = private)

        
        % Read dataset from the directory path
        function readDataset(app)
            % Grab file list by creating a mask of dir entries that are files
            % and applying that mask to the list of the names of the files
            % Then it transposes the array to be a column (using ')
            app.filedata = dir(app.directory);
            filelist = {app.filedata(~[app.filedata.isdir]).name}';

            % Remove all files that are not .h5 files
            % https://stackoverflow.com/a/15604522
            % Throw an error if 154 .h5 files are not found
            filelist = filelist(~cellfun('isempty', regexpi(filelist, '\.h5$')));
            if length(filelist) ~= 155
                errordlg("Error: Unable to use directory - must have 155 .h5 files in directory");
                return;
            end

            % natsort function credit - Stephen Cobeldick
            % https://au.mathworks.com/matlabcentral/fileexchange/34464-customizable-natural-order-sort
            filelist = natsort(filelist);
            
            % Formatting for the table to display the files
            app.UITable.Data = filelist;
            app.UITable.ColumnEditable = false;

            % Get the volume number
            volume = split(filelist{1},'_');
            volume = volume{2};

            % Read data from all files
            for i = 1:155
                filepath = sprintf('%s/volume_%s_slice_%d.h5', app.directory, volume, i-1);
                app.slice_images{i} = h5read(filepath, '/image');
                app.slice_masks{i} = h5read(filepath, '/mask');
            end
            displayImage(app, 75);
        end

        function displayImage(app, slice)
            data = app.slice_images{slice};
            protocol_index = app.protocol_enum(app.protocol);
            % Transpose data so in form MxNx1
            data = permute(data, [2 3 1]);
            % Normalize the image channel to 0-1, then convert to uint8
            image = data(:,:,protocol_index);
            image = (image-min(image(:))) ./ (max(image(:)));
            app.mri_image = im2uint8(image);
            % Set box to correct image size and show
            figsize = size(app.mri_image);
            app.mri_axes.Position = [app.center(1)-figsize(1)/2 app.center(2)-figsize(2)/2 figsize(1) figsize(2)];
            imshow(app.mri_image, "Parent", app.mri_axes);
            
            % Set app properties to new values
            app.slice_shown = slice;
            app.SliceSlider.Value = slice;

            % If tumor mask is toggled on, update tumor mask
            if app.mask_status
                displayMask(app);
            end
        end
        
        function displayMask(app)
            mask = app.slice_masks{app.slice_shown};
            % Transpose data so in form MxNx3, then to grayscale
            mask = permute(mask, [2 3 1]);
            mask = any(mask, 3);
            mask = mat2gray(mask);
          
            % Set shown image to the image with mask overlaid
            overlaid_image = labeloverlay(app.mri_image, mask,"Colormap", 'winter',"Transparency", 0.5);
            app.mri_image = overlaid_image;
            imshow(app.mri_image, "Parent", app.mri_axes);
        end

        function total_area = calculateArea(app)

            total_area = 0;

            % Count the number of 1's in the slice_masks_conventional
            for i = 1:155
                current_slice = app.slice_masks_conventional{i};
                current_slice = any(current_slice, 1);
                current_area = sum(current_slice(:));

                if current_area > total_area
                    total_area = current_area;
                end
            end

            return;
            
        end

        function [volume, slices, masks] = readSample(app, subdirpath)
            subdir = dir(subdirpath);
            slices = cell(155, 1);
            masks = cell(155, 1);
            files = {subdir(~[subdir.isdir]).name};
            volume = split(files{1}, '_');
            volume = volume{2};
            for i = 1:155
                fpath = sprintf('%s/volume_%s_slice_%d.h5', subdirpath, volume, i-1);
                slices{i} = h5read(fpath, '/image');
                masks{i} = h5read(fpath, '/mask');
            end
        end
        
        function volImage = get3DImage(app, slices, protocol_num)
            x_len = length(slices{1}(1,:,1));
            y_len = length(slices{1}(1,1,:));
            volImage = uint8(zeros(x_len, y_len, 155));
            for i = 1:155
                slice = slices{i};
                slice = permute(slice, [2 3 1]);
                image = slice(:, :, protocol_num);
                image = (image-min(image(:))) ./ (max(image(:)));
                image = im2uint8(image);
                volImage(:,:,i) = image;
            end
        end

        function [volumeImages, volumeMask] = buildVolumes(app, slices, masks)
            % Initialize 3D arrays
            volumeImages = cell(4,1);
            for p = 1:4
                volumeImages{p} = app.get3DImage(slices, p);
            end
            volumeMask = uint8(zeros( size(volumeImages{1}) ));
            for i = 1:155 
                mask = masks{i};
                mask = permute(mask, [2 3 1]);
                mask = im2gray(mask);
                volumeMask(:,:,i) = mask;
            end
        end
        
        function radFtrs = extractRadiomicFeatures(app, volumeImages, volumeMask)
            meanImage = (volumeImages{1} + volumeImages{2} + volumeImages{3} + volumeImages{4}) ./ 4;
            tform = affinetform3d();

            volGeometry = medicalref3d(size(meanImage), tform);
            data = medicalVolume(meanImage, volGeometry);

            volGeometry = medicalref3d(size(volumeMask), tform);
            roiData = medicalVolume(volumeMask, volGeometry);

            R = radiomics(data, roiData);
            S = shapeFeatures(R);
            I = intensityFeatures(R);
            T = textureFeatures(R);
            
            radFtrs = zeros(1, 30);
            for f = 1:10
                [~, sCol] = ismember(app.shape_fnames{f}, S.Properties.VariableNames);
                radFtrs(1, f) = table2array(S(1, sCol));

                [~, iCol] = ismember(app.intensity_fnames{f}, I.Properties.VariableNames);
                radFtrs(1, f+10) = table2array(I(1, iCol));

                [~, tCol] = ismember(app.texture_fnames{f}, T.Properties.VariableNames);
                radFtrs(1, f+20) = table2array(T(1, tCol));
            end

        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Set initial value of output image
            app.center = [440, 290];
            figsize = [400 400]; % Initially 400x400, but changes based on image
            app.mri_axes = uiaxes(app.UIFigure);
            app.mri_axes.Position = [app.center(1)-figsize(1)/2 app.center(2)-figsize(2)/2 figsize(1) figsize(2)]; 
            app.mri_axes.XTick = [];
            app.mri_axes.YTick = [];
            app.mri_axes.Box = 'on';

            % Initialize slices data objects
            app.slice_images = cell(155, 1);
            app.slice_masks = cell(155, 1);

            app.slice_shown = -1; % set to -1 if no slice is being shown
            app.protocol = app.ImageAcquisitionProtocolButtonGroup.SelectedObject.Text;
            app.protocol_enum = containers.Map({'T2-FLAIR', 'T1', 'T1Gd', 'T2'}, {1, 2, 3, 4});
            app.mask_status = strcmp(app.ToggleTumorMaskSwitch.Value, "On");

            % Set the radiomic feature names
            app.shape_fnames = {'MinorAxisLength3D', 'LeastAxisLength3D', 'VolumeDensityAEE_3D', 'VolumeMesh3D', 'Elongation3D', ...
                                'VolumeVoxelCount3D', 'MajorAxisLength3D', 'Flatness3D', 'SurfaceVolumeRatio3D', 'SphericalDisproportion3D'};
            app.intensity_fnames = {'DiscretisedIntensitySkewness3D', 'IntensityKurtosis3D', 'MinimumHistogramGradient3D', 'MinimumDiscretisedIntensity3D', 'TenPercentVolumeFraction3D', ...
                                    'VolumeFractionDifference3D', 'DiscretisedIntensityEntropy3D', 'MaximumIntensity3D', 'IntensityHistogramCoeffcientOfVariation3D', 'GlobalIntensityPeak3D'};
            app.texture_fnames = {'InformationCorrelation1Merged3D', 'InformationCorrelation1Averaged3D', 'DependenceCountPercentage3D', 'NormalisedInverseDifferenceMomentMerged3D', 'NormalisedInverseDifferenceMomentAveraged3D', ...
                                  'NormalisedInverseDifferenceMerged3D', 'NormalisedInverseDifferenceAveraged3D', 'InformationCorrelation2Merged3D', 'InformationCorrelation2Averaged3D', 'RunEntropyMerged3D'};
        end

        % Button pushed function: BrowseButton
        function BrowseButtonPushed(app, event)
            selected_dir = uigetdir('', 'Select a Directory');
            % Only call displayFiles if selected_dir points to a new directory
            if selected_dir ~= 0 & ~strcmp(selected_dir, app.directory)
                app.directory = selected_dir;
                readDataset(app);
            end
        end

        % Selection changed function: ImageAcquisitionProtocolButtonGroup
        function ImageAcquisitionProtocolButtonGroupSelectionChanged(app, event)
            app.protocol = app.ImageAcquisitionProtocolButtonGroup.SelectedObject.Text;
            if app.slice_shown ~= -1
                displayImage(app, app.slice_shown);
            end
        end

        % Value changing function: SliceSlider
        function SliceSliderValueChanging(app, event)
            slice = round(event.Value);
            if app.slice_shown ~= -1
                displayImage(app, slice);
            end            
        end

        % Value changed function: ToggleTumorMaskSwitch
        function ToggleTumorMaskSwitchValueChanged(app, event)
            app.mask_status = strcmp(app.ToggleTumorMaskSwitch.Value, "On");
            if app.slice_shown ~= -1
                if app.mask_status
                    displayMask(app)
                else
                    displayImage(app, app.slice_shown);
                end
            end
        end

        % Button pushed function: ExtractConventionalFeaturesButton
        function ExtractConventionalFeaturesButtonPushed(app, event)
            % Create cell array for the headers
            headers = {'Volume_ID', 'area', 'diameter', 'out_layer_involvement'};
            % Write headers and data to a CSV file
            filename = 'conventional_features.csv';
            fid = fopen(filename, 'w');
            if fid == -1
                error('Cannot open file for writing: %s', filename);
            end

            % Write headers
            fprintf(fid, '%s,%s,%s,%s\n', headers{:});


            numRows = 0; %number of rows
            numCols = 4;  %Example number of columns
            app.conventional_data_arr = zeros(numRows, numCols); % Preallocate with 0 values
            

            selected_dir = uigetdir('', 'Select a Directory');            
            app.conventional_dir = selected_dir;
    
            % Get a list of all files in the directory
            files = dir(app.conventional_dir);
            
            for i = 1:length(files)

                if files(i).name == "." || files(i).name == ".." || files(i).name == ".DS_Store"
                    continue;
                end
                
                %initialise variables used for final outputs
                volume = 0;
                maxDiameter = 0;
                total_outer_pixels = 0;
                tumor_outer_pixels = 0;
                
                if files(i).isdir 
                    
                    %obtain current directory
                    current_dir = sprintf('%s/%s', files(i).folder, files(i).name);
                    disp(current_dir);
                    
                    current_filedata = dir(current_dir);
                    current_filelist = {current_filedata(~[current_filedata.isdir]).name}';

                    % natsort function credit - Stephen Cobeldick
                    % https://au.mathworks.com/matlabcentral/fileexchange/34464-customizable-natural-order-sort
                    current_filelist = natsort(current_filelist);

                    %remove all files that aren't .h5 files
                    current_filelist = current_filelist(~cellfun('isempty', regexpi(current_filelist, '\.h5$')));

                    % Get the volume number
                    volume = split(current_filelist{1}, '_');
                    volume = volume{2};
    
                    for j = 1:length(current_filelist)

                        if current_filelist{j} == ".DS_Store" 
                            continue; 
                        end

                        current_filepath = sprintf('%s/volume_%s_slice_%d.h5', current_dir, volume, j-1);
                        %reads the image and the mask
                        app.slice_images_conventional{j} = h5read(current_filepath, '/image');
                        app.slice_masks_conventional{j} = h5read(current_filepath, '/mask');
                        
                        mask = app.slice_masks_conventional{j};
                        % Transpose data so in form 240x240x3, then to grayscale
                        mask = permute(mask, [2 3 1]);
                        mask = any(mask, 3);
                        
                        data = app.slice_images_conventional{j};
                        % Transpose data so in form 240x240x1
                        data = permute(data, [2 3 1]);
                        % Normalize the image channel to 0-1, then convert to uint8
                        image = data(:,:,1);
                        image = (image-min(image(:))) ./ (max(image(:)));

                        % Get the dimensions of the mask
                        [rows, cols] = size(mask);

                        %define a thickness for outer layer
                        thickness = 7;

                        brain_mask = image > 0;
                        
                        %ensure brain mask is not empty
                        if any(brain_mask(:))

                            % Use morphological operations to find the outer layer of the brain
                            se = strel('disk', thickness); % Create a disk-shaped structuring element
                            
                            % Erode the brain mask to get the inner boundary
                            eroded_brain_mask = imerode(brain_mask, se);

                            % Subtract the eroded mask from the original brain mask to get the outer layer
                            outer_layer_mask = brain_mask & ~eroded_brain_mask;
                       
                            % Count the number of tumor pixels in the outer layer
                            tumor_outer_pixels = tumor_outer_pixels + sum(mask(outer_layer_mask) == 1);
                            % Count the total number of pixels in the outer layer
                            total_outer_pixels = total_outer_pixels + sum(outer_layer_mask(:));
    
                        end

                        
                        % Find coordinates of the tumor (where mask is 1)
                        [rows, cols] = find(mask == 1);
                        %combine coordinates into a matrix
                        tumorCoordinates = [rows, cols];
                                     
                        if isempty(tumorCoordinates)
                            continue; % Skip if no tumor is found in this file
                        end

                        % Get the size of tumorCoordinates
                        [numObservations, numVariables] = size(tumorCoordinates);

                        % Check if there are enough observations to perform PCA
                        if numObservations <= numVariables
                            continue;
                        end

   
                        % Perform PCA on the tumor pixel coordinates
                        [~, score, ~] = pca(tumorCoordinates);
                        
                        
                        if isempty(score) || size(score, 2) < 1
                            continue;
                        end
      
                        % Project the tumor pixels onto the first principal component
                        projectedPixels = score(:, 1);
    
                        % Calculate the maximum diameter along the first principal component
                        maxDiameterCurrent = max(projectedPixels) - min(projectedPixels);
            
                        % Update the maximum diameter if the current is larger
                        if maxDiameterCurrent > maxDiameter
                            maxDiameter = maxDiameterCurrent;
                        end

                    end
                    
                    %change volume value from string to double
                    num_vol = str2double(volume);
    
                    %get total max area of tumor
                    total_area = calculateArea(app);
                    
                    maxDiameter = round(maxDiameter , 1); %round to 1 decimal place
    
                    %checks if outer layer pixels is greater than 0
                    if total_outer_pixels > 0 
                        % Calculate the percentage of outer layer involvement
                        percent_outer_involvement = (tumor_outer_pixels / total_outer_pixels) * 100;
                        percent_outer_involvement = round(percent_outer_involvement , 1); %round to 1 decimal place
                    else 
                        percent_outer_involvement = 0;
                    end
                    
                    %store conventional data from current volume in the the convnetional data array       
                    app.conventional_data_arr(end+1,:) = [num_vol,total_area,maxDiameter,percent_outer_involvement];

                end

                
                
            end
            
            %sort the final matrix by volume
            app.conventional_data_arr = sortrows(app.conventional_data_arr, 1);

            %write the matrix to the csv file
            writematrix(app.conventional_data_arr, filename, 'WriteMode', 'append');

            % Close the file
            fclose(fid);
            
            message = sprintf("Extract Conventional Features Completed.\n Saved file to %s", filename);
            msgbox(message);


        end

        % Button pushed function: ExtractRadiomicFeaturesButton
        function RadiomicButtonPushed(app, event)
            dirpath = uigetdir('', 'Select a Directory');
            filename = '.\Features\radiomic_features.csv';
            fid = fopen(filename, 'w');
            if fid == -1
                error('Cannot open file for writing: %s', filename);
            end
            fprintf(fid, ['Volume_ID,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,' ...
                    '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s'], app.shape_fnames{:}, app.intensity_fnames{:}, app.texture_fnames{:});
            selected_dir = dir(dirpath);
            selected_dir = {selected_dir([selected_dir.isdir]).name};
            selected_dir = natsort(selected_dir);
            for d = 3:length(selected_dir)
                subdir = selected_dir{d};
                subdirpath = sprintf('%s/%s', dirpath, subdir);
                disp(subdirpath);
                [volID, slices, masks] = app.readSample(subdirpath);
                vol = sprintf("volume_%s", volID);
                [volumeImages, volumeMask] = app.buildVolumes(slices, masks);
                radFtrs = app.extractRadiomicFeatures(volumeImages, volumeMask);
                outputRow = [vol radFtrs];
                writematrix(outputRow, filename, "WriteMode","append");
                fprintf('\n');
            end
            message = sprintf("Extract Radiomic Features Completed.\n Saved file to %s", filename);
            msgbox(message);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 840 500];
            app.UIFigure.Name = 'MATLAB App';

            % Create UITable
            app.UITable = uitable(app.UIFigure);
            app.UITable.ColumnName = '';
            app.UITable.RowName = {};
            app.UITable.Position = [20 80 200 400];

            % Create BrowseButton
            app.BrowseButton = uibutton(app.UIFigure, 'push');
            app.BrowseButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseButtonPushed, true);
            app.BrowseButton.Interruptible = 'off';
            app.BrowseButton.BackgroundColor = [0.902 0.902 0.902];
            app.BrowseButton.FontName = 'Bahnschrift';
            app.BrowseButton.FontSize = 18;
            app.BrowseButton.FontWeight = 'bold';
            app.BrowseButton.Tooltip = {'Load an Image from File'};
            app.BrowseButton.Position = [60 30 120 30];
            app.BrowseButton.Text = 'Browse...';

            % Create SliceSlider
            app.SliceSlider = uislider(app.UIFigure);
            app.SliceSlider.Limits = [1 155];
            app.SliceSlider.MajorTicks = [1 155];
            app.SliceSlider.MajorTickLabels = {'1', '155'};
            app.SliceSlider.ValueChangingFcn = createCallbackFcn(app, @SliceSliderValueChanging, true);
            app.SliceSlider.BusyAction = 'cancel';
            app.SliceSlider.Position = [270 70 340 3];
            app.SliceSlider.Value = 75;

            % Create ImageAcquisitionProtocolButtonGroup
            app.ImageAcquisitionProtocolButtonGroup = uibuttongroup(app.UIFigure);
            app.ImageAcquisitionProtocolButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ImageAcquisitionProtocolButtonGroupSelectionChanged, true);
            app.ImageAcquisitionProtocolButtonGroup.TitlePosition = 'centertop';
            app.ImageAcquisitionProtocolButtonGroup.Title = 'Image Acquisition Protocol';
            app.ImageAcquisitionProtocolButtonGroup.BackgroundColor = [0.902 0.902 0.902];
            app.ImageAcquisitionProtocolButtonGroup.FontName = 'Bahnschrift';
            app.ImageAcquisitionProtocolButtonGroup.Position = [660 80 160 145];

            % Create T1Button
            app.T1Button = uitogglebutton(app.ImageAcquisitionProtocolButtonGroup);
            app.T1Button.BusyAction = 'cancel';
            app.T1Button.Text = 'T1';
            app.T1Button.BackgroundColor = [1 1 1];
            app.T1Button.FontSize = 14;
            app.T1Button.FontWeight = 'bold';
            app.T1Button.Position = [30 95 100 25];
            app.T1Button.Value = true;

            % Create T1GdButton
            app.T1GdButton = uitogglebutton(app.ImageAcquisitionProtocolButtonGroup);
            app.T1GdButton.BusyAction = 'cancel';
            app.T1GdButton.Text = 'T1Gd';
            app.T1GdButton.FontSize = 14;
            app.T1GdButton.FontWeight = 'bold';
            app.T1GdButton.Position = [30 65 100 25];

            % Create T2FLAIRButton
            app.T2FLAIRButton = uitogglebutton(app.ImageAcquisitionProtocolButtonGroup);
            app.T2FLAIRButton.BusyAction = 'cancel';
            app.T2FLAIRButton.Text = 'T2-FLAIR';
            app.T2FLAIRButton.FontSize = 14;
            app.T2FLAIRButton.FontWeight = 'bold';
            app.T2FLAIRButton.Position = [30 35 100 25];

            % Create T2Button
            app.T2Button = uitogglebutton(app.ImageAcquisitionProtocolButtonGroup);
            app.T2Button.BusyAction = 'cancel';
            app.T2Button.Text = 'T2';
            app.T2Button.FontSize = 14;
            app.T2Button.FontWeight = 'bold';
            app.T2Button.Position = [30 5 100 25];

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.FontName = 'Bahnschrift';
            app.Label.FontSize = 14;
            app.Label.Position = [423 30 25 22];
            app.Label.Text = '';

            % Create ToggleTumorMaskSwitchLabel
            app.ToggleTumorMaskSwitchLabel = uilabel(app.UIFigure);
            app.ToggleTumorMaskSwitchLabel.HorizontalAlignment = 'center';
            app.ToggleTumorMaskSwitchLabel.FontName = 'Bahnschrift';
            app.ToggleTumorMaskSwitchLabel.FontSize = 14;
            app.ToggleTumorMaskSwitchLabel.FontWeight = 'bold';
            app.ToggleTumorMaskSwitchLabel.Position = [677 255 125 25];
            app.ToggleTumorMaskSwitchLabel.Text = 'Toggle Tumor Mask';

            % Create ToggleTumorMaskSwitch
            app.ToggleTumorMaskSwitch = uiswitch(app.UIFigure, 'slider');
            app.ToggleTumorMaskSwitch.ValueChangedFcn = createCallbackFcn(app, @ToggleTumorMaskSwitchValueChanged, true);
            app.ToggleTumorMaskSwitch.FontName = 'Bahnschrift';
            app.ToggleTumorMaskSwitch.FontSize = 14;
            app.ToggleTumorMaskSwitch.FontWeight = 'bold';
            app.ToggleTumorMaskSwitch.Position = [715 290 45 20];

            % Create ExtractConventionalFeaturesButton
            app.ExtractConventionalFeaturesButton = uibutton(app.UIFigure, 'push');
            app.ExtractConventionalFeaturesButton.ButtonPushedFcn = createCallbackFcn(app, @ExtractConventionalFeaturesButtonPushed, true);
            app.ExtractConventionalFeaturesButton.Position = [650 457 180 23];
            app.ExtractConventionalFeaturesButton.Text = 'Extract Conventional Features ';

            % Create ExtractRadiomicFeaturesButton
            app.ExtractRadiomicFeaturesButton = uibutton(app.UIFigure, 'push');
            app.ExtractRadiomicFeaturesButton.ButtonPushedFcn = createCallbackFcn(app, @RadiomicButtonPushed, true);
            app.ExtractRadiomicFeaturesButton.Position = [650 424 181 23];
            app.ExtractRadiomicFeaturesButton.Text = 'Extract Radiomic Features';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = gliomaApp_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end