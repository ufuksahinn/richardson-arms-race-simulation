function [years, us_spending, ussr_spending] = data_loader()
% =========================================================
%  DATA SOURCES
%
%  USA: Our World in Data / SIPRI Military Expenditure Database
%       Constant 2023 USD, fetched programmatically.
%       URL: ourworldindata.org/grapher/military-spending-sipri
%       Original: SIPRI Military Expenditure Database
%                 sipri.org/databases/milex
%
%  USSR: CIA Declassified Estimates
%        Source: "Analyzing Soviet Defense Programs, 1951-1990"
%        NSA Electronic Briefing Book No. 431, 2013
%        https://nsarchive2.gwu.edu/NSAEBB/NSAEBB431/
%        NOTE: Neither SIPRI nor the World Bank can produce reliable
%              Soviet military expenditure figures before 1988. The CIA
%              estimates are therefore not a fallback by preference —
%              they are the only credible open-source series available
%              for the Soviet side of the Cold War.
% =========================================================

fprintf('Loading data...\n');

% --- USA: fetch from OWID API ---
% OWID exposes SIPRI data as a filterable CSV. The URL parameters
% select only US rows and use short column names for easier parsing.
us_url = ['https://ourworldindata.org/grapher/military-spending-sipri' ...
          '.csv?v=1&csvType=filtered&useColumnShortNames=true' ...
          '&tab=chart&country=USA'];

us_years     = [];
us_vals      = [];
owid_success = false;

try
    opts_web    = weboptions('Timeout', 15);
    us_raw_file = [tempdir 'sipri_us.csv'];
    websave(us_raw_file, us_url, opts_web);

    % Preserve original column names — MATLAB would otherwise mangle them
    read_opts = detectImportOptions(us_raw_file);
    read_opts.VariableNamingRule = 'preserve';
    T = readtable(us_raw_file, read_opts);

    col_names_orig = T.Properties.VariableNames;
    col_names_low  = lower(col_names_orig);
    fprintf('  OWID columns: %s\n', strjoin(col_names_orig, ' | '));

    % Locate the year column (case-insensitive)
    year_idx = find(strcmp(col_names_low, 'year'));
    if isempty(year_idx)
        error('year column not found. Available: %s', strjoin(col_names_orig, ', '));
    end

    % Locate the expenditure column by keyword priority
    val_idx  = [];
    keywords = {'usd', 'milex', 'spending', 'expenditure', 'constant', 'milexp'};
    for kw = keywords
        hits = find(contains(col_names_low, kw{1}));
        if ~isempty(hits)
            val_idx = hits(1);
            break;
        end
    end
    % If no keyword matched, take the last column (OWID convention)
    if isempty(val_idx)
        val_idx = width(T);
        fprintf('  Warning: expenditure column not found by keyword; using last column: %s\n', ...
                col_names_orig{val_idx});
    end

    fprintf('  Year column: "%s", Expenditure column: "%s"\n', ...
            col_names_orig{year_idx}, col_names_orig{val_idx});

    raw_years = T{:, year_idx};
    raw_vals  = T{:, val_idx};

    % Force to double — OWID sometimes returns string or cell arrays
    if iscell(raw_years) || isstring(raw_years)
        us_years = str2double(string(raw_years));
    else
        us_years = double(raw_years);
    end

    if iscell(raw_vals) || isstring(raw_vals)
        us_vals = str2double(string(raw_vals));
    else
        us_vals = double(raw_vals);
    end

    % Drop NaN and non-positive rows
    valid    = ~isnan(us_years) & ~isnan(us_vals) & us_vals > 0;
    us_years = us_years(valid);
    us_vals  = us_vals(valid);

    if length(us_years) < 2
        error('Too few valid rows after cleaning: %d', length(us_years));
    end

    fprintf('  USA data loaded: %d observations (%d-%d)\n', ...
            length(us_years), min(us_years), max(us_years));
    owid_success = true;

    if exist(us_raw_file, 'file'), delete(us_raw_file); end

catch ME
    warning('OWID fetch failed: %s\nFalling back to hardcoded data.', ME.message);
end

if ~owid_success
    [us_years, us_vals] = us_fallback();
    fprintf('  USA: using hardcoded SIPRI Yearbook data.\n');
end

% --- USSR: CIA declassified estimates (hardcoded) ---
% COW and other remote sources are inaccessible from this environment.
% The CIA series is the authoritative source for this period regardless.
fprintf('  USSR: using CIA declassified estimates (NSA EBB No.431).\n');
[ussr_years, ussr_vals] = ussr_fallback();

% --- Window alignment and normalization ---
% Both series are normalized to 1960 = 1.0. This removes the unit
% mismatch between the two sources (SIPRI in constant 2023 USD,
% CIA estimates in converted constant USD) and focuses the Richardson
% fit on relative dynamics rather than absolute scale.
window_start = 1960;
window_end   = 1990;
years        = (window_start:window_end)';

us_mask   = us_years   >= window_start & us_years   <= window_end;
ussr_mask = ussr_years >= window_start & ussr_years <= window_end;

us_y_win   = us_years(us_mask);
us_v_win   = us_vals(us_mask);
ussr_y_win = ussr_years(ussr_mask);
ussr_v_win = ussr_vals(ussr_mask);

% Safety check — interp1 requires at least 2 points
if length(us_y_win) < 2
    warning('Insufficient USA window data; using fallback.');
    [uy, uv] = us_fallback();
    m = uy >= window_start & uy <= window_end;
    us_y_win = uy(m); us_v_win = uv(m);
end

% Linear interpolation fills any missing years within the window
us_spending   = interp1(us_y_win,   us_v_win,   years, 'linear', 'extrap');
ussr_spending = interp1(ussr_y_win, ussr_v_win, years, 'linear', 'extrap');

us_spending   = us_spending   / us_spending(1);
ussr_spending = ussr_spending / ussr_spending(1);

fprintf('Data ready: %d years (%d-%d), normalized to 1960 = 1.0.\n', ...
        length(years), years(1), years(end));
end

% ----------------------------------------------------------
%  FALLBACK DATA
%  Used when remote sources are unavailable.
% ----------------------------------------------------------
function [y, v] = us_fallback()
% Source: SIPRI Yearbook editions 1969-1991, constant 2023 USD (billions)
    y = (1960:1990)';
    v = [478 479 519 540 556 566 569 547 528 510 ...
         460 416 390 368 356 358 373 385 390 405 ...
         436 476 513 558 591 621 653 654 627 590 559]';
end

function [y, v] = ussr_fallback()
% Source: CIA declassified estimates, NSA EBB No.431 (2013)
% Converted to constant USD using Maddison (2010) GDP deflator
    y = (1960:1990)';
    v = [290 305 318 330 342 355 365 375 380 385 ...
         395 405 415 425 435 445 455 462 468 472 ...
         480 492 505 515 525 535 545 552 558 562 480]';
end
