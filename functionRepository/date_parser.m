function D = date_parser(dd,mm,yy)
%this functions receives string formats of different dates and translates
%it to matlab date format. that way, the manual enties o dates van be
%compared with harware time logs of matlab.
switch mm
    case '01' %| '1'
        mm= 'Jan';
    case '02' %| '2'
        mm= 'Feb';
    case '03' %| '3'
        mm= 'Mar'
    case '04' %| '4'
        mm= 'Apr';
    case '05' %| '5'
        mm= 'May';
    case '06' %| '6'
        mm= 'Jun';
    case '07' %| '7'
        mm= 'Jul';
    case '08' %| '8'
        mm= 'Aug';
    case '09' %| '9'
        mm= 'Sep';
    case '10'
        mm= 'Oct';
    case '11'
        mm= 'Nov';
    case '12'
        mm= 'Dec';
end
switch yy
    case '19'
        yy = '2019';
    case '20'
        yy = '2020';
    case '21'
        yy = '2021';
    case '22'
        yy = '2022';
end
D=[dd,'-',mm,'-',yy]
end