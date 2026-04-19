% Note: This test file has been partially created using the testing code 
% from 
% https://github.com/chervud/AGD-vs-Sinkhorn
% and adapted for our purposes.

%This set of tests executes a comparison with the Sinkhorn algorithm.

%Import the compiled Java code for our algorithm.
%For the javaaddpath command, use the directory of the Java .class files.
clear java;
clc;

%Add all files of project to path
addpath(genpath('../'));

javaaddpath('..\GabowTarjanJavaCode\GTTransport\bin\')
import optimaltransport.*;
%disp(javaclasspath)

%methodsview('optimaltransport.ScaledMapping')

load('mnist.mat', 'testX')  

disp("Running in single threaded mode.")
maxNumCompThreads(1);

% example with set of written digits. Use digits.mat as input data
data = importdata('mnist.mat');
digits = testX';
results = table;

%size of an image
scale = 1; %multiplier for the number of pixels
m = 28*scale; %m x m - 2-dim grid, size of the support = m^2
%size of the support of the measures
n = m*m;

%Computes euclidean  distances.
C = computeDistanceMatrixGrid(m);

%Square the distances to get squared Euclidean distances.
C = C.*C;

%normalize cost matrix to set natural scale
%Ensures that C = 1;
C = C / max(max(C)); 
maxC = max(max(C));

%initialize parameters

deltas = [0.1, 0.01, 0.001, 0.0001];
delta_times = cell(size(deltas));  % Cell array to store time taken for each delta
delta_lengths = cell(size(deltas));  % Cell array to store lengths of augmented paths for each delta
delta_iterations = cell(size(deltas));  % Array to store number of iterations for each delta

runs = 1; %number of runs of the experiment

%Get the supplies and demands from the image pixels.
for k = 1:1:runs
    disp("Starting run #" + num2str(k));
    %load images from MNIST
    %generate image number
    
    i = ceil(rand*size(digits,2));
    j = ceil(rand*size(digits,2));
    
    imageIndex1 = i;
    imageIndex2 = j;
    aa = im2double(digits(:,i));
    bb = im2double(digits(:,j));
    aa = aa/sum(aa);
    bb = bb/sum(bb);
    aa = reshape(aa, m/scale, m/scale);
    aa = my_im_resize(scale,scale,aa);
    a = reshape(aa, m*m, 1);
    bb = reshape(bb, m/scale, m/scale);
    bb = my_im_resize(scale,scale,bb);
    b = reshape(bb, m*m, 1);
    b = b/sum(b);
    
    I = (a==0);
    a(I) =  0.000001; % Wherever in a an entry is 0 it would now be replaced with 0.000001
    I = (b==0);
    b(I) =  0.000001;
    
    a = a/sum(a);
    b = b/sum(b);  
    

    y1 = [];
    y2 = [];
    x = [];
   
    %% Verify solutions using LINPROG
    i = 1;
    for d = 1:numel(deltas)
        delta = deltas(d);
        %% Run Scaled GTTransport
        disp('Start GT Algorithm')

        iteration_times = [];
        AP_lengths = [];
        iteration_counts = [];
        current_delta = 1.0;
        x(i) = current_delta;

        gtSolver = optimaltransport.ScaledMapping(n, a, b', C, current_delta); %This is the transport plan for scaled supplies and demands delta = 1.0
        gtSolver1 = optimaltransport.Mapping(n, a, b', C, current_delta);
        pattern = 'timeTaken=(\d+)';

        % Extract the matched value
        match = regexp(char(gtSolver.getString()), pattern, 'tokens');
        match1 = regexp(char(gtSolver1.getString()), pattern, 'tokens');
        y(i) = str2double(match{1}{1});
        y1(i) = str2double(match1{1}{1});
        i = i + 1;

        disp("current_delta = " + current_delta);
        disp("Time taken to solve current_delta with warm starts = " + gtSolver.getTimeTaken());
        disp("Time taken to solve current_delta without warm starts = " + gtSolver1.getTimeTaken());
        disp("------------------------------------------------------------------------------------");
        current_delta = current_delta / 2;
        duals = gtSolver.getDuals();
        GTTransport_time = gtSolver.getTimeTaken(); 
        iteration_times(d) =  GTTransport_time;
        GTTransportMainRoutineTime = gtSolver.getMainRoutineTimeInSeconds();
        APLengths = gtSolver.getAPLengths();
        %AP_lengths = [AP_lengths, APLengths];
        iterationCountTransport = gtSolver.getIterations();
        %iteration_counts = [iteration_counts, iterationCountTransport];


        % Run GTTransport for each delta value
        disp("Solving for delta = " + delta);
        %disp("Total number of iterations = " + log2(1/delta));
        while current_delta > delta
            %disp('r = ' +  string(r));
            %disp('Start GT Algorithm for delta = ' + string(current_delta));
            
            gtSolver = optimaltransport.ScaledMapping(n, a, b', C, current_delta,duals,false); 
            gtSolver1 = optimaltransport.Mapping(n, a, b', C, current_delta);
            duals = gtSolver.getDuals();

            pattern = 'timeTaken=(\d+)';

            % Extract the matched value
            match = regexp(char(gtSolver.getString()), pattern, 'tokens');
            match1 = regexp(char(gtSolver1.getString()), pattern, 'tokens');
            y(i) = str2double(match{1}{1});
            y1(i) = str2double(match1{1}{1});
            x(i) = current_delta;
            i = i + 1;

            disp("current_delta = " + current_delta);
            disp("Time taken to solve current_delta with warm starts = " + gtSolver.getTimeTaken());
            disp("Time taken to solve current_delta without warm starts = " + gtSolver1.getTimeTaken());
            disp("------------------------------------------------------------------------------------");
            iteration_times(d) =  gtSolver.getTimeTaken();
            GTTransport_time = GTTransport_time + gtSolver.getTimeTaken();
            %iteration_times = [iteration_times, GTTransport_time];
            GTTransportMainRoutineTime = GTTransportMainRoutineTime + gtSolver.getMainRoutineTimeInSeconds();
        
            %flow = gtSolver.getFlow();
            %total_cost_transport = gtSolver.getTotalCost();
            iterationCountTransport = iterationCountTransport + gtSolver.getIterations();
            %iteration_counts = [iteration_counts, iterationCountTransport];
            APLengths = APLengths + gtSolver.getAPLengths();
            %AP_lengths = [AP_lengths, APLengths];
            augmentTime = gtSolver.getTimeTakenAugment();

            %augmentTime is 0 if the timing code is commented out in the Java 
            %implementation.
            %Precise timing could negatively affect performance.
            %If the time taken from augmentations is important,
            %then uncomment the timing calls in the Java code.
            if augmentTime == 0
                augmentTime = -1;
            end

            %% Check to ensure that the solution is a valid transport plan.
            %tolerance = 0.000000001;
            %residualSupply = b';
            %residualDemand = a;
            %for i = 1:n
                %for j = 1:n
                    %assert(flow(i,j) >= -tolerance);
                    %residualSupply(i) = residualSupply(i) - flow(i,j);
                    %residualDemand(i) = residualDemand(i) - flow(j,i);
                %end
                %assert(abs(residualSupply(i)) <= tolerance);
                %assert(abs(residualDemand(i)) <= tolerance);
            %end

            % Calculating Error
    
            % Saving results
            current_delta = current_delta / 2;

        end
        gtSolver = optimaltransport.ScaledMapping(n, a, b', C, current_delta,duals,true);
        gtSolver1 = optimaltransport.Mapping(n, a, b', C, current_delta);
        current_delta = current_delta / 2;
        duals = gtSolver.getDuals();
        x(i) = current_delta;



        pattern = 'timeTaken=(\d+)';

        % Extract the matched value
        match = regexp(char(gtSolver.getString()), pattern, 'tokens');
        match1 = regexp(char(gtSolver1.getString()), pattern, 'tokens');
        y(i) = str2double(match{1}{1});
        y1(i) = str2double(match1{1}{1});
        i = i + 1;

        disp("current_delta = " + current_delta);
        disp("Time taken to solve current_delta with warm starts = " + gtSolver.getTimeTaken());
        disp("Time taken to solve current_delta without warm starts = " + gtSolver1.getTimeTaken());
        disp("------------------------------------------------------------------------------------");
        iteration_times = gtSolver.getTimeTaken();
        GTTransport_time = GTTransport_time +  gtSolver.getTimeTaken(); 

        GTTransportMainRoutineTime = GTTransportMainRoutineTime + gtSolver.getMainRoutineTimeInSeconds();
    
        flow = gtSolver.getFlow();
        total_cost_transport1 = gtSolver1.getTotalCost();
        total_cost_transport = gtSolver.getTotalCost();
        disp("Total Cost for OT with warm starts is " + total_cost_transport);
        disp("Total Cost for OT without warm starts is " + total_cost_transport1);
        disp("Absolute Difference between OT costs with and without warm starts is equal to " + abs(total_cost_transport1 - total_cost_transport));
        disp("GTTransport time for OT with warm starts " + GTTransport_time);
        disp("GTTransport time for OT without warm starts " + gtSolver1.getTimeTaken);
        disp("GTTransport Main Routine time for OT with warm starts " + GTTransportMainRoutineTime);
        disp("GTTransport Main Routine time for OT without warm starts " + gtSolver1.getMainRoutineTimeInSeconds);
        disp("Iteration times for each iteration is " + iteration_times);
        iterationCountTransport = iterationCountTransport + gtSolver.getIterations();
        %iteration_counts = [iteration_counts, iterationCountTransport];
        APLengths = APLengths + gtSolver.getAPLengths();
        %AP_lengths = [AP_lengths, APLengths];
        augmentTime = gtSolver.getTimeTakenAugment();

        %augmentTime is 0 if the timing code is commented out in the Java 
        %implementation.
        %Precise timing could negatively affect performance.
        %If the time taken from augmentations is important,
        %then uncomment the timing calls in the Java code.
        if augmentTime == 0
            augmentTime = -1;
        end

            %% Check to ensure that the solution is a valid transport plan.
        tolerance = 0.000000001;
        residualSupply = b';
        residualDemand = a;
        for i = 1:n
            
            for j = 1:n
                assert(flow(i,j) >= -tolerance);
                residualSupply(i) = residualSupply(i) - flow(i,j);
                residualDemand(i) = residualDemand(i) - flow(j,i);
            end
            assert(abs(residualSupply(i)) <= tolerance);
            assert(abs(residualDemand(i)) <= tolerance);
        end

        % Calculating Error

        % Saving results
        %newRow = {k, maxC, current_delta, GTTransport_time, GTTransportMainRoutineTime, iterationCountTransport, APLengths, augmentTime, imageIndex1, imageIndex2};
        %results = [results; newRow];

        figure;
        Y = [y; y1];
        bar(x,Y);
        i = 1;
        y1 = [];
        y2 = [];
        x = [];

        newRow = {k, maxC, delta, GTTransport_time, GTTransportMainRoutineTime, iterationCountTransport, APLengths, augmentTime, imageIndex1, imageIndex2};
        results = [results; newRow];

        % TODO - Need a for loop from which will call gtSolver as shown below from which we can get the scaled dual weights and call gtSolver again.   
        delta_times{d} = [delta_times{d}; iteration_times];  % Store times for current delta
        delta_lengths{d} = [delta_lengths{d}; AP_lengths];  % Store lengths for current delta
        delta_iterations{d} = [delta_iterations{d}; iteration_counts];  % Update total iterations for current delta 
    end
end

% % Calculate total time, total AP lengths, and total iterations for each delta
% total_times = cellfun(@sum, delta_times, 'UniformOutput', false);
% total_lengths = cellfun(@sum, delta_lengths, 'UniformOutput', false);
% total_iterations = cellfun(@sum, delta_iterations, 'UniformOutput', false);

% % Display results
% for d = 1:numel(deltas)
%     disp("Delta: " + deltas(d));
%     disp("Total Time: " + string(total_times{d}));
%     disp("Total AP Lengths: " + string(total_lengths{d}));
%     disp("Total Iterations: " + string(total_iterations{d}));
% end

results.Properties.VariableNames = {'run', 'C', 'delta', 'GTTime', 'GTTransportMainRoutineTime', 'GTIter', 'GTAPLengths', 'AugmentTime', 'ImageOneIndex', 'ImageTwoIndex'};
%% Generate average results
avgResults = varfun(@mean,results,'InputVariables',{'GTTime', 'GTTransportMainRoutineTime', 'GTIter','GTAPLengths', 'AugmentTime' },'GroupingVariables',{'delta'});
disp(avgResults);



