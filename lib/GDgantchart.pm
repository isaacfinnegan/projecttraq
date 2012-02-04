#!/usr/bin/perl
###############################################################
#    Copyright (C) 2001-2007 Isaac Finnegan and Sean Tompkins
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
###############################################################



package GDgantchart;

require Exporter;
require 'timelocal5.pm';

&timelocal_set_package('GDgantchart');

@ISA = qw(Exporter);
@EXPORT = qw(GantChart);



use GD;

#NOTE:  yInc should normally be a multiple of ygrid, if not specifying low 
#       and high values for y.

	local (%parm) = ();
	local (@barcolrs);
	local ($g, $v);
	local ($i, $j, $k, $mapstr);
sub GantChart
{
	my ($x, $y, $ix, $v, $maxxsiz, $maxysiz); 
#print "<BR><BR>entering GDgantchart!\n";

	%parm = ();
	@barcolors = ();
	while (@_)
	{
		$v = shift;
		$v =~ s/^\-//;
		$parm{$v} = shift;
#print "<BR>111 parm name=$v= set to =$parm{$v}=\n";
	}


goto SKIPDEBUG1;
#print "<BR>????? *START* ????? barysiz=$parm{barysiz}=\n";



#print "<BR>HELLO WORLD:  xcnt=$#{$parm{xvals}}= ycnt=$#{$parm{tasks}}=\n";

			for ($i=0;$i<$#{$parm{xvals}};$i++)
			{
#print "<BR>xxxx=${$parm{xvals}}[$i]=\n";
			}
			for ($i=0;$i<$#{$parm{tasks}};$i++)
			{
#print "<BR>yyyy=${$parm{tasks}}[$i]=\n";
			}

SKIPDEBUG1:

	my (%startendpoints);

	local ($sfw,$sfh) = (gdSmallFont->width,gdSmallFont->height);
	local ($lfw,$lfh) = (gdLargeFont->width,gdSmallFont->height);
	my ($sfh2) = $sfh + 2;
	my ($sfh5) = $sfh + 5;

	#SET UP PARAMETER DEFAULTS.

	$parm{lmgn} = 40  unless($parm{lmgn});
	$parm{rmgn} = 40  unless($parm{rmgn});
	$parm{bmgn} = 40  unless($parm{bmgn});
	unless(defined($parm{tmgn}))
	{
		$parm{tmgn} = 50;
	}
	$parm{tmgn} += $lfh  if (defined($parm{title}));
	$parm{valcolor} = 'white'  unless ($parm{valcolor});
	$parm{axiscolor} = 'black'  unless ($parm{axiscolor});
	$parm{titlecolor} = $parm{axiscolor}  unless ($parm{titlecolor});
	$parm{valxcolor} = $parm{axiscolor}  unless ($parm{valxcolor});
	$parm{barcolors} = [qw(gray)]  unless(defined($parm{barcolors}));
	if (defined($parm{barcolor}))
	{
		$parm{barcolors} = [$parm{barcolor}];
	}
	else
	{
		$parm{barcolor} = ${$parm{barcolors}}[0];
	}
	my ($shadowcolor) = 'black';
	if (defined($parm{shadowcolor}))
	{
		$shadowcolor = $parm{shadowcolor};
	}
	else
	{
		if (defined($parm{bgcolor}))
		{
			$shadowcolor = 'gray'  if ($parm{bgcolor} =~ /black/i);
		}
	}
	$parm{headercolor} = $parm{barcolor}  unless ($parm{headercolor});
	$parm{gridcolor} = $parm{headercolor}  unless ($parm{gridcolor});
	$parm{bordercolor} = 'black'  unless ($parm{bordercolor});
        $parm{shadowcolor} = $shadowcolor;

#print "<BR> ymin=$parm{ymin}; ymax=$parm{ymax}; yInc=$parm{yInc}; \n";

	if ($parm{xlegendchars})
	{
		for $ix (0..$#{$parm{tasks}})
		{
			$i = substr($parm{tasks}->[$ix],0,$parm{xlegendchars});
			$parm{tasks}->[$ix] = $i . '..'  
				unless (length($parm{tasks}->[$ix]) <= $parm{xlegendchars});
		}
	}
	unless (defined($parm{xlegendsiz}))
	{
		if (defined($parm{tasks}))  #IF LEGENDS WIDER THAN CHART, WIDEN CHART!
		{
			for $ix (0..$#{$parm{tasks}})
			{
#print "??? task($ix)=${$parm{tasks}}[$ix]= len=".length(${$parm{tasks}}[$ix])."=\n";
				$i = $sfw * (length(${$parm{tasks}}[$ix])+2);
#print "??? xls=$parm{xlegendsiz}= i=$i=\n";
				$parm{xlegendsiz} = $i  if ($parm{xlegendsiz} < $i);
			}
		}
	}
	else
	{
		$xlegendsiz = $parm{xlegendsiz};
	}
#print "??? xlegendsiz=$parm{xlegendsiz}=\n";
	unless (defined($parm{ylegendsiz}))
	{
		#if (defined($parm{xvals}))  #IF LEGENDS WIDER THAN CHART, WIDEN CHART!
		#{
		#	foreach $ix (@{$parm{xvals}})
		#	{
		#		$i = $sfw * (length(${$parm{xvals}}[$ix])+2);
		#		$parm{ylegendsiz} = $i  if ($parm{ylegendsiz} < $i);
		#	}
		#}
		$parm{ylegendsiz} = $sfh5 + 5;
	}
	unless ($parm{barxsiz})
	{
		$barxsiz = 0;
		foreach (@{$parm{xvals}})   #FIND WIDEST X HEADER TO COMPUTE LINE SIZE.
		{
			$i = $sfw * (length($_)+1);
			$barxsiz = $i  unless ($barxsiz > $i);
		}
	}
	unless ($parm{xsiz})
	{
		$parm{barxsiz} = $barxsiz  unless ($parm{barxsiz});
		$maxxsiz = ($parm{barxsiz} * ($#{$parm{xvals}}+1)) 
				+ $parm{xlegendsiz} + $parm{lmgn} + $parm{rmgn};
		&fixedxsiz($parm{minxsiz})  
				if ($parm{minxsiz} && $maxxsiz < $parm{minxsiz});
		&fixedxsiz($parm{maxxsiz})  
				if ($parm{maxxsiz} && $maxxsiz > $parm{maxxsiz});
		$parm{maxxsiz} = $maxxsiz;
	}
	else    #CHART'S MAXIMUM SIZE PRESET BY abUSER.
	{
		&fixedxsiz($parm{xsiz});
	}
	unless ($parm{ysiz})    #CALCULATE MAXIMUM CHART HEIGHT.
	{
		$parm{barysiz} = $sfh5  unless ($parm{barysiz} 
				&& $parm{barysiz} > $sfh5);
		$maxysiz = ($parm{barysiz} * ($#{$parm{tasks}}+1)) + $parm{ylegendsiz} 
				+ $parm{bmgn} + $parm{tmgn};
		&fixedysiz($parm{minysiz})  
				if ($parm{minysiz} && $maxysiz < $parm{minysiz});
		&fixedysiz($parm{maxysiz})  
				if ($parm{maxysiz} && $maxysiz > $parm{maxysiz});
		$parm{maxysiz} = $maxysiz;
	}
	else    #CHART HEIGHT IS FIXED BY abUSER.
	{
		&fixedysiz($parm{ysiz});
	}
	unless ($parm{barpct})
	{
		$parm{barpct} = 50;
		$parm{barpct} = 100  if ($parm{barysiz} < 10);
	}
	my ($chartxsizml) = $parm{barxsiz} * ($#{$parm{xvals}}+1);
	$chartxsiz = $chartxsizml + $parm{xlegendsiz};  #(PIXELS)
	$chartysiz = ($parm{barysiz} * ($#{$parm{tasks}}+1)) 
			+ $parm{ylegendsiz};  #(PIXELS)

#print "<BR>----final values: maxxsiz=$parm{maxxsiz}; maxysiz=$parm{maxysiz}; ybase=$parm{ybase}; yInc=$parm{yInc}; ygrid=$parm{ygrid}= ymax=$parm{ymax}.\n";
	$g = new GD::Image($parm{maxxsiz},$parm{maxysiz});

@rgbcolors = <<LINES  =~ m/(\S.*\S)/g;
255 255 255		white
  0   0   0		black
190 190 190		gray
190 190 190		grey
211 211 211		lightgrey
211 211 211		lightgray
  0   0 128		navy
  0   0 128		navyblue
  0   0 128		NavyBlue
  0   0 255		blue
173 216 230		lightblue
173 216 230		LightBlue
  0 255 255		cyan
224 255 255		lightcyan
224 255 255		LightCyan
  0 100   0		darkgreen
  0 100   0		DarkGreen
  0 180   0		green
127 255   0		chartreuse
240 230 140		khaki
255 255 224		lightyellow
255 255 224		LightYellow
255 255   0		yellow
255 215   0 	gold
218 165  32		goldenrod
245 245 220		beige
210 180 140		tan
210 105  30		chocolate
165  42  42		brown
255 165   0		orange
255 140   0		darkorange
255 140   0		DarkOrange
255   0   0		red
255 192 203		pink
255 182 193		lightpink
255 182 193		LightPink
176  48  96		maroon
255   0 255		magenta
238 130 238		violet
160  32 240		purple
149 149 149		darkgrey
149 149 149		darkgray
0     0 139		darkblue
139   0   0		darkred
144 238 144		lightgreen
LINES


	#CONVERT COLOR NAMES TO RGB VALUES.
	my($line);
	foreach $line (@rgbcolors)
	{
		chomp;
		($rr,$gg,$bb,$color) = split(' ',$line);
		$color = "\L$color\E";
		foreach (qw(bar bg val axis grid title valx header border shadow))
		{
			$x = $parm{$_."color"};
			${$_."colr"} = $g->colorAllocate($rr,$gg,$bb)  if ($color eq "\L$x\E");
		}
		for($j=0;$j<=$#{$parm{barcolors}};$j++)
		{
			if ($color eq "\L${$parm{barcolors}}[$j]\E")
			{
				$i = $g->colorAllocate($rr,$gg,$bb);
				$barcolrs[$j] = $i;
			}
		}
	}
	my (@colorindex) = (0..$#{$parm{barcolors}});
	for ($j=0;$j<$parm{shiftcolors};$j++)
	{
		$ix = shift(@barcolrs);
		@barcolrs = (@barcolrs,$ix);
	}

	if($parm{linecolor})
	{
		$linecolor = $g->colorAllocate($parm{linecolor}[0],$parm{linecolor}[1],$parm{linecolor}[2]);
	}

	#SET UP DEFAULTS FOR ANY MISSING COLORS.

	$barcolr = $g->colorAllocate(0,0,0)  unless ($barcolr);
	$valcolr = $g->colorAllocate(0,0,0)  unless ($valcolr);
	$axiscolr = $g->colorAllocate(0,0,0)  unless ($axiscolr);
	$gridcolr = $g->colorAllocate(0,0,0)  unless ($gridcolr);
	$shadowcolr = $g->colorAllocate(0,0,0)  unless ($shadowcolr);
	$bgcolr = $g->colorAllocate(250,250,250)  unless ($bgcolr);
	$linecolor = $g->colorAllocate(0,250,0) unless ($linecolor);

	if ($#barcolrs <= 0)    #FILL OUT COLOR ARRAY WITH BAR-COLOR IF NOT SPECIFIED.
	{
		for ($j=0;$j<=$#{$parm{tasks}};$j++)
		{
			$barcolrs[$j] = $barcolr;
		}
	}
	elsif ($#barcolrs < $#{$parm{tasks}})    #FILL OUT COLOR ARRAY TO MATCH Y-ARRAY.
	{
		for ($j=$#barcolrs+1;$j<$#{$parm{tasks}};$j++)
		{
			$barcolrs[$j] = $barcolrs[($j % $#barcolrs)];
		}
	}

	if (defined($parm{bgcolor}))
	{
#print "<BR>??? bgcolor=$parm{bgcolor}= bgcolr=$bgcolr=\n";
		$g->transparent($bgcolr);  #MAKE THE BACKGROUND COLOR TRANSPARENT.
		#$g->fill(1,1,$bgcolr);
	}
	for (0..($parm{border}-1))
	{
		$g->rectangle($_,$_,($parm{maxxsiz}-($_+1)),($parm{maxysiz}-($_+1)),$bordercolr);
	}
	##my $barylo = $parm{tmgn} + ($chartysiz * (($parm{ymax}-$parm{ybase}) / ($parm{ymax}-$parm{ymin})));

	#SET UP IMAGE MAPPING, IF APPLICABLE.

	if (defined($parm{links}) || defined($parm{mouseovers})
			|| defined($parm{link}) || defined($parm{mouseover}))
	{
		$parm{mapname} = "BarChart.$$"  unless (defined($parm{mapname}));
		$mapstr = '<MAP NAME="' . $parm{mapname} . '">' . "\n";
	}

	#DRAW THE CHART FRAME.

	my ($tmgn2) = $parm{tmgn} + ($parm{ylegendsiz}/2);
	my ($xlo) = $parm{lmgn} + $parm{xlegendsiz};
	$x = $xlo;

#print "??? xlegendsiz=$parm{xlegendsiz}=\n";
	$g->rectangle($parm{lmgn}, $parm{tmgn}, ($parm{lmgn}+$chartxsiz),
			($parm{tmgn}+$chartysiz), $axiscolr);
	$g->line($x, $parm{tmgn}, 
			$x, ($parm{tmgn}+$chartysiz), 
			$axiscolr);
	$g->line($parm{lmgn}, ($parm{tmgn}+$parm{ylegendsiz}), 
			($parm{lmgn}+$chartxsiz), ($parm{tmgn}+$parm{ylegendsiz}), 
			$axiscolr);
	$g->line($x, 
			$tmgn2, ($parm{lmgn}+$chartxsiz), 
			$tmgn2, $axiscolr);
	my ($xhi) = $parm{lmgn} + $chartxsiz;
	my ($ylo) = $parm{tmgn} + $parm{ylegendsiz};
	my ($myxlo, $myxhi, $myylo, $myyhi);
	my ($chlo) = &char2time($parm{starttime});
	my ($barythick) = ($parm{barpct}/100) * $parm{barysiz};
	my ($chspan) = &char2time($parm{endtime}) - $chlo;
	my ($chartpix);
	if ($chspan > 0)
	{
		$chartpix = $chartxsizml / $chspan;
	}
	else
	{
		$chartpix = 1;
	}

	$g->line($xlo, $tmgn2, $xhi, $tmgn2, $axiscolr);

	#OK, LET'S DRAW THE CHART ITSELF!

	$y = $tmgn2 + (((($tmgn2+($parm{ylegendsiz}/2)) - $tmgn2)- $sfh) / 2) + 1;
	#$y = ($parm{tmgn} + ($parm{ylegendsiz} - 5) - ($sfh/2));
	#$j = $parm{tmgn} + $chartysiz;
	$j = $parm{tmgn} + $parm{ylegendsiz};
#print "??? barxsiz=$parm{barxsiz}=\n";
	for $i (0..$#{$parm{xvals}})
	{
		if (${$parm{xticks}}[$i])
		{
			$myxhi = $xlo + (&char2time(${$parm{xticks}}[$i])-$chlo) * $chartpix;
			$g->line($myxhi, $tmgn2, $myxhi, $j, $axiscolr);
		}
		else
		{
			$g->line($x, $tmgn2, $x, $j, $axiscolr);
		}
		$g->string(gdSmallFont, 
				($x+(($parm{barxsiz}-(length(${$parm{xvals}}[$i])*$sfw))/2)), 
				$y, ${$parm{xvals}}[$i], $headercolr);
		$x += $parm{barxsiz};
	}
	$j = $parm{tmgn} + $chartysiz;
	$j += 3  if ($#{$parm{xlegend}} >= 0);
	#$k = $parm{tmgn} + ((($tmgn2 - $parm{tmgn})- $sfh) / 2) + 1;
	$k = $parm{tmgn} + ((($tmgn2 - $parm{tmgn})- $sfh) / 2);
	$myxlo = $xlo;
	for $i (0..$#{$parm{xbreaks}})
	{
		$myxhi = $xlo + (&char2time(${$parm{xbreaks}}[$i])-$chlo) * $chartpix;
		$g->line($myxhi, $parm{tmgn}, $myxhi, $tmgn2, $gridcolr);
		$g->line($myxhi, ($parm{tmgn} + $parm{ylegendsiz}), $myxhi, $j, $gridcolr);
		if (${$parm{xlegend}}[$i])
		{
			$g->string(gdSmallFont, 
					($myxhi-(((length(${$parm{xlegend}}[$i])*$sfw))/2)), 
					$j, ${$parm{xlegend}}[$i], $headercolr);
		}
		if (${$parm{xtlegend}}[$i])
		{
			if ($myxhi == $myxlo)
			{
				$g->string(gdSmallFont, 
						($myxlo + (($parm{barxsiz}-
	                            ((length(${$parm{xtlegend}}[$i])*$sfw)))
	                            /2)), 
						$k, ${$parm{xtlegend}}[$i], $headercolr);
			}
			else
			{
				$g->string(gdSmallFont, 
						($myxlo + ((($myxhi-$myxlo)-
	                            ((length(${$parm{xtlegend}}[$i])*$sfw)))
	                            /2)), 
						$k, ${$parm{xtlegend}}[$i], $headercolr);
			}
		}
		$myxlo = $myxhi;
	}
#print "--- maxxsiz=$parm{maxxsiz}= maxysiz=$parm{maxysiz}=\n";
	$x = $xlo;
	$j = $ylo;
	$y = ($ylo + ($sfh / 2)) - 2;
	$myylo = $ylo + ($parm{barysiz} - $barythick) / 2;
	$myydlo = $ylo + ($parm{barysiz} / 2);
	my ($dw, $dh) = (5, 8);   #DIAMOND WIDTH/HEIGHT (PIXELS).
	my ($x1) = $parm{lmgn} + $sfw + ($sfw/2);
	my ($rawtime);
	my ($rawstart) = &char2time($parm{starttime});
	my ($rawend) = &char2time($parm{endtime});
	my ($completepct);

	$ix = 0;
#print "<BR>??? barpct=$parm{barpct}= chspan=$chspan= chxsiz=$chartxsiz= chartpix=$chartpix=\n";
	for $i (0..$#{$parm{tasks}})
	{
		$rawtime = &char2time(${$parm{starttimes}}[$ix]);
		if ($rawtime < $rawstart && ${$parm{starttimes}}[$ix])   #DRAW LEFT ARROW AT LOW END OF CHART.
		{
			$rawtime = $rawstart-1;
			$myxlo = ($xlo + ($rawtime-$chlo) * $chartpix) - $dw;
			$g->line($myxlo, $myydlo, ($myxlo+$dw), ($myydlo-$dh), $barcolrs[$ix]);
			$g->line(($myxlo+$dw), ($myydlo-$dh), ($myxlo+$dw), ($myydlo+$dh), $barcolrs[$ix]);
			$g->line(($myxlo+$dw), ($myydlo+$dh), $myxlo, $myydlo, $barcolrs[$ix]);
			$g->fill($myxlo+2, $myydlo, $barcolrs[$ix]);
			
			$line_xlo = $myxlo-$dw;
			$line_xhi = $myxlo+$dw;
			$line_ylo = $myydlo-$dh;
			$line_yhi = $myydlo+$dh;
		}
		#elsif ($rawtime > $rawend)
		#{
		#	$rawtime = $rawend + 1;
		#}
		$myxlo = $xlo + ($rawtime-$chlo) * $chartpix;
#print " needed=".(5*$sfw)."= start=".($myxlo+$dw+3)."= end=".($parm{lmgn}+$chartxsiz)."=\n";
#print "<BR>myxlo=$myxlo= xlo=$xlo= xhi=$xhi=\n";
		if (${$parm{starttimes}}[$ix] eq ${$parm{endtimes}}[$ix] && ${$parm{endtimes}}[$ix]) #DRAW DIAMOND.
		{
			if ($xlo <= $myxlo && $myxlo <= $xhi)   #DRAW DIAMOND MARKING SINGLE POINT.
			{
				$g->line(($myxlo-$dw), $myydlo, $myxlo, ($myydlo-$dh), $barcolrs[$ix]);
				$g->line($myxlo, ($myydlo-$dh), ($myxlo+$dw), $myydlo, $barcolrs[$ix]);
				$g->line(($myxlo+$dw), $myydlo, $myxlo, ($myydlo+$dh), $barcolrs[$ix]);
	
				$g->line($myxlo, ($myydlo+$dh), ($myxlo-$dw), $myydlo, $barcolrs[$ix]);
				$line_xlo = $myxlo-$dw;
				$line_xhi = $myxlo+$dw;
				$line_ylo = $myydlo-$dh;
				$line_yhi = $myydlo+$dh;
				if (defined $parm{complete}[$ix])
				{
					$completepct = ($parm{complete}[$ix]  > 1.0) ? 
							($parm{complete}[$ix] / 100.0) : $parm{complete}[$ix];
					if ($completepct >= 0.5)
					{
						$g->fill($myxlo-1, $myydlo, $barcolrs[$ix]);
						$g->fill($myxlo+1, $myydlo, $barcolrs[$ix]);
					}
				}
				else
				{
					$g->fill($myxlo-1, $myydlo, $barcolrs[$ix]);
					$g->fill($myxlo+1, $myydlo, $barcolrs[$ix]);
				}
				unless ($parm{nosingles})   #PRINT DATE NEXT TO DIAMOND ON SINGLE POINTS.
				{
					if ((($parm{lmgn}+$chartxsiz)-($myxlo+$dw+3)) <= (5*$sfw))
					{
						$g->string(gdSmallFont, (($myxlo-$dw)-(5*$sfw+3)), $y-$dh, 
							substr(&prettydate(${$parm{starttimes}}[$ix]),0,5), $headercolr);
					}
					else
					{
						$g->string(gdSmallFont, ($myxlo+$dw+3), $y-$dh, 
							substr(&prettydate(${$parm{starttimes}}[$ix]),0,5), $headercolr);
					}
				}
			}
		}
		elsif(${$parm{endtimes}}[$ix])      #DRAW BAR
		{
			$myyhi = $myylo + $barythick;
			$rawtime = &char2time(${$parm{endtimes}}[$ix]);
			if ($rawtime > $rawend)   #DRAW RIGHT ARROW AT END OF CHART.
			{
				$rawtime = $rawend+1;
				$myxhi = $xlo + ($rawtime-$chlo) * $chartpix;
				$myxhi += ($dw + 1)  if ($parm{rmgn} > $dw);
				$g->line($myxhi, $myydlo, ($myxhi-$dw), ($myydlo+$dh), $barcolrs[$ix]);
				$g->line(($myxhi-$dw), ($myydlo+$dh), ($myxhi-$dw), ($myydlo-$dh), $barcolrs[$ix]);
				$g->line(($myxhi-$dw), ($myydlo-$dh), $myxhi, $myydlo, $barcolrs[$ix]);
				$g->fill($myxhi-2, $myydlo, $barcolrs[$ix]);
			}
			$myxhi = $xlo + ($rawtime-$chlo) * $chartpix;
			if (defined $parm{complete}[$ix] && ($myxhi > $myxlo))
			{
				$completepct = ($parm{complete}[$ix]  > 1.0) ? 
						($parm{complete}[$ix] / 100.0) : $parm{complete}[$ix];
				$l = $myxlo + ($completepct * ($myxhi - $myxlo));
#print "<BR>xlo=$myxlo/$xlo= l=$l= xhi=$myxhi/$xhi= cmp=$completepct=\n";
				$g->filledRectangle($myxlo,$myylo,$l,$myyhi,$barcolrs[$ix]);
				$g->rectangle($l,$myylo,$myxhi,$myyhi,$barcolrs[$ix]);
			}
			else
			{
				$g->filledRectangle($myxlo,$myylo,$myxhi,$myyhi,$barcolrs[$ix]);
			}
			$line_xlo = $myxlo;
			$line_xhi = $myxhi;
			$line_ylo = $myylo;
			$line_yhi = $myyhi;
		}

		if ( $line_xlo && $line_ylo && $line_xhi && $line_yhi )
		{
			$startendpoints{$parm{links}[$ix]}{startx} = $line_xlo;
			$startendpoints{$parm{links}[$ix]}{starty} = $line_ylo;
			$startendpoints{$parm{links}[$ix]}{endx} = $line_xhi;
			$startendpoints{$parm{links}[$ix]}{endy} = $line_yhi;
		}
		$line_xlo = undef;
		$line_ylo = undef;
		$line_xhi = undef;
		$line_yhi = undef;

#print "---??? rectangle($myxlo,$myylo,$myxhi,$myyhi,$barcolrs[$ix])\n";


		if (defined($parm{links}[$i]) || defined($parm{mouseovers})   #ADD HYPERLINK, IF ANY, TO BAR.
				|| defined($parm{link}) || defined($parm{mouseover}))
		{
			my ($l) = 'HREF="//';
			if (defined($parm{links}[$i]) || defined($parm{link}))
			{
				$parm{links}[$i] = $parm{link}  unless($parm{links}[$i]);
				$l = ' HREF="' . $parm{links}[$i];
				unless ($l =~ m#\"\s*(http\:|\/)#)
				{
					$l = 'HREF="' . $parm{linkpath};
					$l .= $parm{links}[$i]  unless ($l =~ s#\*#$parm{links}[$i]#);
				}
			}
			$l .= '"';
			$l = ''  if ($l eq 'HREF="//"' && !defined($parm{mouseovers}[$ix]));   #ADDED 20000302!
			$mapstr .= '<AREA SHAPE=rect COORDS="' . $parm{lmgn} . ',' .
					$j . ',' . $xhi . ',' .
					($j+$parm{barysiz}) . '" ' . $l;
			if (defined($parm{mouseovers}[$i]))   #ADD MOUSEOVER LINK, IF ANY, TO BAR.
			{
				$mapstr .= " onmouseover=\"window.status='$parm{mouseovers}[$i]'; return true\"";
			}
			elsif (defined($parm{mouseover}))      #ADD DEFAULT MOUSEOVER LINK, IF ANY.
			{
				$mapstr .= " onmouseover=\"window.status='$parm{mouseover}'; return true\"";
			}
			$mapstr .= ">\n";
			
			
		}


		$j += $parm{barysiz};
		$g->line($parm{lmgn}, $j, $x, $j, $axiscolr);
		$g->string(gdSmallFont, $x1, $y, ${$parm{tasks}}[$i], $headercolr);
		$y += $parm{barysiz};
		$myylo += $parm{barysiz};
		$myydlo += $parm{barysiz};
		++$ix;
	}

	#FINISH UP HYPERLINKS, IF NECESSARY.
#print "<BR>Done with main chart.\n";

	if (defined($parm{links}) || defined($parm{mouseovers})
			|| defined($parm{link}) || defined($parm{mouseover}))
	{
		$l = 'HREF="//';
		if (defined($parm{link}))
		{
			$l = 'HREF="' . $parm{link};
			#$l = $parm{linkpath} . $l  unless ($l =~ m#^\s*(http\:|\/)#);
			unless ($l =~ m#\"\s*(http\:|\/)#)
			{
				$l = "HREF=\"$parm{linkpath}";
				$l .= $parm{link}  unless ($l =~ s#\*#$parm{link}#);
			}
		}
		$l .= '"';
		if (defined($parm{link}) || defined($parm{mouseover}))
		{
			$mapstr .= '<AREA SHAPE=default ' . $l;
			$mapstr .= " onmouseover=\"window.status='$parm{mouseover}'; return true\""
					if (defined($parm{mouseover}));
			$mapstr .= ">\n";
		}
		$mapstr .= '</MAP>' . "\n";
	}

 	my %depmap = %{$parm{depmap}};
 	for my $ic (0..$#{$parm{links}})
 	{
 		if ( $depmap{$parm{links}[$ic]} )
 		{
 			for my $i (0..$#{@depmap{$parm{links}[$ic]}})
 			{
 				if ( $startendpoints{$depmap{$parm{links}[$ic]}[$i]} && $startendpoints{$parm{links}[$ic]} )
				{
					my ($linestartx,$linestarty,$lineendx,$lineendy);
					my ($linehalfy);
					$linestartx = $startendpoints{$depmap{$parm{links}[$ic]}[$i]}{endx};
					$linestarty = (($startendpoints{$depmap{$parm{links}[$ic]}[$i]}{endy} - $startendpoints{$depmap{$parm{links}[$ic]}[$i]}{starty}) / 2) + $startendpoints{$depmap{$parm{links}[$ic]}[$i]}{starty}; 					
					$lineendx = $startendpoints{$parm{links}[$ic]}{startx};
					$lineendy = (($startendpoints{$parm{links}[$ic]}{endy} - $startendpoints{$parm{links}[$ic]}{starty}) / 2) + $startendpoints{$parm{links}[$ic]}{starty};
	
					$linehalfy = (($lineendy - $linestarty) / 2) + $linestarty;
					$g->line($linestartx, $linestarty, $linestartx + 7.5, $linestarty, $linecolor);
					$g->line($linestartx + 7.5, $linestarty, $linestartx + 7.5, $linehalfy, $linecolor);
					$g->line($linestartx + 7.5, $linehalfy, $lineendx - 7.5, $linehalfy, $linecolor);
					$g->line($lineendx - 7.5, $linehalfy, $lineendx -7.5, $lineendy, $linecolor);
					$g->line($lineendx - 7.5, $lineendy, $lineendx, $lineendy, $linecolor);
	
					my ($arrowheadend) = new GD::Polygon;
					$arrowheadend->addPt($lineendx - 3,$lineendy - 3);
					$arrowheadend->addPt($lineendx - 3,$lineendy + 3);
					$arrowheadend->addPt($lineendx,$lineendy);
					$g->filledPolygon($arrowheadend,$linecolor);
				}
 			}
 		}
 	}
	
	
	#PRINT MAIN HEADERS AND TITLES.

	if (defined($parm{title}))
	{
		if ($parm{tmgn} > $lfh)
		{
			$g->string(gdLargeFont, 
					(($chartxsiz - ($lfw*length($parm{title})))/2) + $parm{lmgn},
					($parm{tmgn} - $lfh) / 2, $parm{title}, $titlecolr);
		}
	}
	if (defined($parm{xtitle}))
	{
		if ($parm{bmgn} > $sfh)
		{
			$j = $sfw * length($parm{xtitle});
			$x = ($chartxsiz - $j)/2;
			$x = 0  if ($x < 0);
			$x += $parm{lmgn}  unless (($j+$parm{lmgn}) > $parm{maxxsiz});
#print "<BR>j=$j= x=$x= lmgn=$parm{lmgn}= maxx=$parm{maxxsiz}/$maxxsiz=\n";
			$y = $parm{tmgn}+$chartysiz+$sfh;
			$y = $parm{tmgn}+$chartysiz+(($parm{bmgn}-$sfh)/2)  
					if ($parm{bmgn} < 40);
			$y = $parm{tmgn} + $chartysiz + $sfh + 4  if ($#{$parm{xbreaks}} >= 0);
			$g->string(gdSmallFont, $x, $y, $parm{xtitle}, $titlecolr);
		}
	}
	if (defined($parm{ytitle}))
	{
		if ($parm{lmgn} > $sfh)
		{
			$i = $sfw*length($parm{ytitle});
			$x = ($parm{lmgn}-(2*$sfh));
			$x = ($parm{lmgn}-$sfh) / 2  if ($parm{lmgn} < 40);
			#$g->stringUp(gdSmallFont, ($parm{lmgn}-$sfh) / 2, 
			#		(($chartysiz - $i)/2) + $i + $parm{tmgn}, 
			#		$parm{ytitle}, $titlecolr);
			$g->stringUp(gdSmallFont, $x, 
					(($chartysiz - $i)/2) + $i + $parm{tmgn}, 
					$parm{ytitle}, $titlecolr);
		}
	}
	return ($g,$mapstr);	
}

sub fixedxsiz
{
	$maxxsiz = shift;

#print "??? maxxsize set to =$maxxsiz= by abuser!\n";
	#$x = $maxxsiz / 2;  #REDUCE LEGEND-SIZE TO AT MOST 1/2 OF CHART.
	#$parm{xlegendsiz} = $x  if ($parm{xlegendsiz} > $x);
#print "??? p(bs)=$parm{barxsiz}= bs=$barxsiz= ls=$parm{xlegendsiz}=\n";
	unless ($parm{barxsiz})
	{
		$parm{barxsiz} = ($maxxsiz - ($parm{lmgn} + $parm{rmgn} 
				+ $parm{xlegendsiz})) / ($#{$parm{xvals}}+1);
#print "??? p(bs)=$parm{barxsiz}= bs=$barxsiz= ls=$parm{xlegendsiz}=\n";
		$barxsiz -= $sfw;
		if ($parm{barxsiz} < $barxsiz)   #IF WON'T FIT, EAT THE MARGINS!
		{
			$parm{barxsiz} = $barxsiz;
			$parm{lmgn} = $parm{rmgn} = ($maxxsiz 
					- ($parm{xlegendsiz} + (($#{$parm{xvals}}+1)*$parm{barxsiz}))) / 2;
#print "??? lmgn=$parm{lmgn}=\n";
			if ($parm{lmgn} < 0)  #NO MARGINS LEFT, SHRINK MONTHS.
			{
				$parm{barxsiz} = ($maxxsiz - $parm{xlegendsiz}) 
						/ ($#{$parm{xvals}}+1);
				$parm{lmgn} = $parm{rmgn} = 0;

				if ($parm{barxsiz} < $barxsiz && $parm{xlegendsiz} > ($maxxsiz / 4))
				{
					### STILL WONT FIT, TRY REDUCING LEGEND!

					unless ($parm{keeplegend})
					{
						$parm{xlegendsiz} = $maxxsiz / 4;
						$parm{xlegendsiz} = $parm{xminlegendsiz}  if ($parm{xlegendsiz} < $parm{xminlegendsiz});
						#$parm{barxsiz} = (3 * $maxxsiz) / (4 * ($#{$parm{xvals}}+1));
						$parm{barxsiz} = ($maxxsiz - $parm{xlegendsiz}) 
								/ ($#{$parm{xvals}}+1);
						$x = int($parm{xlegendsiz} / $sfw) - 2;
						for $i (0..$#{$parm{tasks}})
						{
							${$parm{tasks}}[$i] =~ s/\s+$//;
							$j = ${$parm{tasks}}[$i];
							${$parm{tasks}}[$i] = substr($j,0,$x); 
							${$parm{tasks}}[$i] = substr($j,0,($x-2)) . '..' 
									unless ($j eq ${$parm{tasks}}[$i]);
						}
					}
				}
			}
			if ($parm{barxsiz} < $barxsiz)  #ADJUST MONTH NAMES
			{
				$x = int($parm{barxsiz} / $sfw);
				for $i (0..$#{$parm{xvals}})
				{
					${$parm{xvals}}[$i] =~ s/\s+$//;
					$j = ${$parm{xvals}}[$i];
					${$parm{xvals}}[$i] = substr($j,0,$x);
					#${$parm{xvals}}[$i] = substr($j,0,($x-2) . '..') 
					#		unless ($j eq ${$parm{xvals}}[$i]);
				}
			}
		}
	}
	$parm{maxxsiz} = $maxxsiz;
}

sub fixedysiz
{
	$maxysiz = shift;
#	$parm{barysiz} = 20;
	unless ($parm{barysiz})   #CALCULATE HEIGHT(PIXELS) FOR EACH TASK.
	{
#print "??? taskcount=$#{$parm{tasks}}=\n";
		$parm{barysiz} = ($maxysiz - ($parm{tmgn} + $parm{bmgn} 
				+ $parm{ylegendsiz})) / ($#{$parm{tasks}}+1);
		if ($parm{barysiz} < $sfh5)   #IF WON'T FIT, EAT THE MARGINS!
		{
			$parm{barysiz} = ($maxysiz - $parm{ylegendsiz}) 
					/ ($#{$parm{tasks}}+1);
			$parm{tmgn} = $parm{bmgn} = $maxysiz 
					- ((($#{$parm{tasks}}+1)*$parm{barysiz})) * 2;
			$parm{tmgn} = 0  if ($parm{tmgn} < 0);
			$parm{bmgn} = 0  if ($parm{bmgn} < 0);
			if ($parm{barysiz} < $sfh5) #IF STILL WON'T FIT, TRUNCATE CHART!
			{
				$#{$parm{tasks}} = int(($maxysiz-$parm{ylegendsiz}) 
						/ $sfh5);
				$parm{tmgn} = $parm{bmgn} = ($maxysiz 
						- (($#{$parm{tasks}} * $sfh5) 
						+ $parm{ylegendsiz})) / 2;
			}
		}
	}
	$parm{maxysiz} = $maxysiz;
}

sub char2time
{
require 'timelocal5.pm';

&timelocal_set_package('GDgantchart');
	my ($dtmstr) = shift;

	my ($datepart, $timepart) = split(/\:/,$dtmstr);
	$datepart = '00000000'  unless (length($datepart) >= 8);
	my $mm = substr($datepart,4,2);
	my $yyyy = substr($datepart,0,4);
	
	$timepart = ' 0 0'  unless ($timepart =~ /\S/);
	$timepart .= ' 0'  unless (length($timepart) > 3);
	$yyyy -= 1900  if ($yyyy >= 1900);   #NOT A Y2K PROBLEM!
	$mm--;
	my ($res) = &timelocal(0, substr($timepart,2,2), substr($timepart,0,2), 
			substr($datepart,6,2), $mm, $yyyy, 0, 0, 0);
	$res;
}

sub prettydate       #CONVERT "yyyymmdd" to "mm/dd/yyyy".
{
	my ($dt) = shift;
	
	$dt =~ s/\n//g;  #SPECIAL TO HANDLE A DATABASE GLITCH ;-)
	my ($res) = (substr($dt,4,2) . '/' . substr($dt,6,2) . '/' . substr($dt,0,4));
	if (length($dt) > 8)
	{
		my ($xm) = 'AM';
		$res .= ' ';
		my ($hr) = substr($dt,9,2);
		$hr = substr($dt,10,1)  unless ($hr > 9);
		if ($hr > 12)
		{
			$xm = 'PM';
			$hr -= 12  if ($hr > 12);
		}
		elsif ($hr == 0)
		{
			$hr += 12;
			$xm = 'AM';
		}
		elsif ($hr == 12)
		{
			$xm = 'PM';
		}
		$res .= "$hr" . ':' . substr($dt,11,2);
	}
	return ($res);
}

1

