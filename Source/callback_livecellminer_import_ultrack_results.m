function [d_orgs] = callback_livecellminer_import_ultrack_results(outputPathTracking, parameters)

    %% load all tracked images
    fileList = dir([outputPathTracking '*.png']);
    numFrames = length(fileList);

    %% load tracked csv file
    %% format: id,track_id,t,y,x,id,parent_track_id,parent_id
    ultrackID = 1;
    ultrackTrackID = 2;
    ultrackT = 3;
    ultrackY = 4;
    ultrackX = 5;
    ultrackID2 = 6;
    ultrackParentTrackID = 7;
    ultrackParentID = 8;
    trackingTable = dlmread([outputPathTracking 'ultrack_result_table.csv'], ',', 1, 0);

    %% convert frames to 1-based indices
    trackingTable(:, 3) = trackingTable(:, 3) + 1;

    %% var_bez = char('id', 'scale', 'xpos', 'ypos', 'zpos', 'prevXPos', 'prevYPos', 'prevZPos', 'clusterCutoff', 'trackletId', 'predecessorId');
    d_orgs = zeros(max(trackingTable(:,2)), numFrames, 13);
    for i=1:size(trackingTable, 1)

        currentTrackID = trackingTable(i, ultrackTrackID);
        currentPosition = trackingTable(i, [ultrackX, ultrackY]);
        currentT = trackingTable(i, ultrackT);
        currentParentTrackID = trackingTable(i, ultrackParentTrackID);

        d_orgs(currentTrackID, currentT, 1) = currentTrackID;
        d_orgs(currentTrackID, currentT, 2) = 0;
        d_orgs(currentTrackID, currentT, 3:4) = currentPosition;
        d_orgs(currentTrackID, currentT, parameters.trackingIdIndex) = currentTrackID;
        d_orgs(currentTrackID, currentT, parameters.predecessorIdIndex) = currentParentTrackID;
    end
end
