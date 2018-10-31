function [recorded, det] = deadtime2_fast(t, pulse,  N_det, t_dead_analog, t_dead_digital_ch1, t_dead_digital_ch2)
% NOTE: t and pulse must be sorted by pulse, then by time.

% Alex S. Gardner, JPL-Caltech

det = ceil(rand(size(t))*N_det);
recorded = false(size(t));

t_dead_digital_max = max(t_dead_digital_ch1, t_dead_digital_ch2);
t_dead_digital_min = min(t_dead_digital_ch1, t_dead_digital_ch2);

% the analog detector limits the throughput to the digital detector so
% you only need to search a maximum of t_dead_digita/t_dead_analog
% photons away from a detection event

maxPhtn = ceil(t_dead_digital_max/t_dead_analog);
    
% loop for each detector
for i = 1:N_det
    
    idx = det == i;
    t0 = t(idx);
    pulse0 = pulse(idx);
    
    % ----------- Analog paralyzable detector -----------
    % photons that arive at least t_dead_analog after last event 
    dt0 = [0; (t0(2:end) -t0(1:(end-1)))];
    recorded0 = dt0 > t_dead_analog;
    
    % first photon in pulse always regesters
    firstPhtn = [true; (pulse0(2:end) -pulse0(1:(end-1))) ~= 0];
    
    % photon events that pass through to the Analog detector to the digital
    % detector
    idxA = recorded0 | firstPhtn;
    
    % ----------- Digital non-paralyzable electronics -----------
    
    % time of events that make it through to the digitalizing electronics
    t0 = t0(idxA);
    dt0 = dt0(idxA);
    firstPhtn = firstPhtn(idxA);
    
    if t_dead_digital_min == t_dead_digital_max

        % find recorded events assuming paralyzable electronics (first pass)
        recorded0 = (dt0 > t_dead_digital_min) | firstPhtn;
        
        % first photon after an event is not recorded because < t_dead_digital
        nextInLine = [0; recorded0(1:end-1)] & ~recorded0;
        
        % move to second in line
        nextInLine = [0; nextInLine(1:end-1)] & ~recorded0;
        
        cum_dt = dt0;
        while any(nextInLine)
            cum_dt(recorded0) = 0;
            cum_dt = dt0 + [0; cum_dt(1:end-1)];
            recorded0(cum_dt > t_dead_digital_min & nextInLine) = true;
            nextInLine = [0; nextInLine(1:end-1)] & ~recorded0;
        end
    else
        % find recorded events assuming paralyzable electronics (first pass)
        recorded0 = (dt0 > t_dead_digital_max) | firstPhtn;
        maxSrch = length(t0);
        
        % only search photons event that are spaced < max(t_dead_digitalA,
        % t_dead_digitalB) to see if they fall after digital detector deadtime
        chkPhtn = ~recorded0;

        while any(chkPhtn)
            chkPhtn0 = find(chkPhtn,1,'first');
            idx0 = (chkPhtn0):min((chkPhtn0+maxPhtn), maxSrch);
            
            % truncate before next detection
            foo = find(recorded0(idx0),1, 'first') - 1;
            if ~isempty(foo)
                idx0 = idx0(1:foo);
            end
            
            % time since last event
            cum_dt = cumsum(dt0(idx0));
            
            % all events fall inside of both channel deadtimes
            if all(cum_dt <  t_dead_digital_min)
                chkPhtn(idx0) = 0;
                %fprintf('no event\n')
                continue
            else
                
                % deremine if odd or even event
                % ** random selection of start chann should really be implimented for each pulse **
                if mod(sum(recorded0(1:(idx0(1)-1))),2) ~= 0 % first channel
                    %fprintf('channel-1\n')
                    t_dead_digital = t_dead_digital_ch1;
                else
                    %fprintf('channel-2\n')
                    t_dead_digital = t_dead_digital_ch2;
                end
                
                foo = find(cum_dt > t_dead_digital,1,'first');
                if ~isempty(foo)
                    %fprintf('event\n')
                    recorded0(idx0(foo)) = true;
                    chkPhtn(idx0(1:foo)) = false;
                else
                    %fprintf('no event\n')
                    chkPhtn(idx0) = 0;
                end
            end
        end
    end
    
    foo = find(idxA);
    idxA(foo(~recorded0)) = false;
    recorded(idx) = idxA;
end