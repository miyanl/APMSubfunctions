function visu2d(X,fac,angle,x0,dx,y0,dy)
% visu2d.m        Affichage de signaux sous forme juxtaposee
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% visu2d(X,fac,angle,x0,dx,y0,dy)
%
% Auteur : J. Idier	Date : 07/94	Version 1.3 d'apres plot2d
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%      Cette fonction permet d'afficher cote a cote un ensemble 
% de signaux juxtaposes en lignes ou en colonnes dans une matrice Matlab.
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% (X):	Donnees a visualiser. Eventuellement, remplacer par
%	X - mean(min(X)) pour eviter les derives si X>0.
% (fac): Facteur d'echelle : une valeur positive donne
%	l'empietement maximum d'un signal sur un signal
%	voisin, une valeur negative donne un decalage
%	absolu entre axes des abscisses des signaux
%	consecutifs. Valeur par defaut : 1 (aucun empietement).
% (angle): de 0 a 90. Traces empiles horizontalement si orient = 0,
%	decales entre 0 et 90, empilees verticalement si angle = 90.
% (x0): Indice a l'origine (0 par defaut) de chaque signal.
% (dx): Pente de l'echelle par rapport a la numerotation 
%	matricielle de X (1 par defaut) pour chaque signal.
% (y0): Indice du premier signal (1 par defaut).
% (dy): Pente de l'echelle entre deux signaux (1 par defaut).
%
% Voir aussi plot2d, geoplot
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%
%	Parameter initialisation
%
	if exist('angle') ~= 1    	% If no type parameter has been set
		angle = 0;		% Set it to default value
	end
	if exist('x0')~=1
		x0 = 0;
	end
	if exist('dx')~=1
		dx = 1;
	end
	dx = abs(dx);
	if exist('y0')~=1
		y0 = 1;
	end
	if exist('dy')~=1
		dy = 1;
	end
	dy = abs(dy);
	if exist('fac')~=1
		fac = 1.5;
	elseif fac == 0      		% Else, test if it is null
		fprintf('Error. The scaling factor must non null\n')
		return            	% Message and exit
	end
	if fac > 0
		M = max(abs(X(:)));	% Maximum of the absolute value of the data
		fac = fac/M;		% for relative scaling
	else
		fac = -1/fac;    	% Negative values of fac give absolute scaling
	end
%	clf
	plot(1,1,'k')
	hold on
%
   if rem(angle-90,180)~=0		% Cas general : signaux en ligne
	[Nl,Nc] = size(X);
	vecc = x0 + dx*(0:Nc-1);	% Scaling of the data points 
	vecl = y0 + dy*(0:Nl-1); 
	X = vecl(ones(1,Nc),:)' + X*fac;	
	coeff = abs(tan(angle*pi/180));
	plot(vecc(ones(1,Nl),:)'+coeff*(vecl(ones(1,Nc),:)-y0),X','-w')
%	plot(vecc,X,'-w')

	dy0 = Nl*dy/20;
	ym = min(y0-dy0, min(X(:))-dy0);
	yM = max(y0+(Nl-1)*dy+dy0, max(X(:))+dy0);
	dx0 = Nc*dx/60;
	xM = x0 + (Nc-1)*dx + dx0 + coeff*dy*Nl;
	xm = x0 - dx0;
	axis([xm xM ym yM])
	
	ymark = get(gca,'YTick');
	ymark = ymark(ymark<Nl);
	yl = length(ymark);
	yspace = ymark(yl)-ymark(1);
	if (vecl(Nl)-ymark(yl))*yl*5<yspace
	    ymark(yl) = vecl(Nl);
	else
	    ymark = [ymark vecl(Nl)];
	end
	if (ymark(1)-vecl(1))*yl*5<yspace
	    ymark(1) = vecl(1);
	else
	    ymark = [vecl(1) ymark];
	end
		
	xmark = get(gca,'XTick');
	xmark = xmark(1:sum(xmark<vecc(Nc)));
	xl = length(xmark);
	xspace = xmark(xl)-xmark(1);
	if (vecc(Nc)-xmark(xl))*xl*3.5<xspace
	    xmark(xl) = vecc(Nc);
	else
	    xmark = [xmark vecc(Nc)];
	end
	if (xmark(1)-vecc(1))*xl*3.5<xspace
	    xmark(1) = vecc(1);
	else
	    xmark = [vecc(1) xmark];
	end

	plot([xmark;xmark+coeff*(yM-ym)],[ym;yM],'w:')
	plot([xm;xM],[ymark;ymark],'w:')
	set(gca,'XTick',xmark,'YTick',ymark)
	hold off

    else				% Rotation de 90 degres
	X = X';
	[Nl,Nc] = size(X);
	vecc = y0 + dy*(0:Nc-1);	% Scaling of the data points 
	vecl = x0 + dx*(0:Nl-1); 	
	X = vecc(ones(1,Nl),:) + X*fac;	
	plot(X,vecl,'-w')
	
	dy0 = Nc*dy/60;
	xm = min(y0-dy0,min(X(:))-dy0);
	xM = max(y0+(Nc-1)*dy+dy0,max(X(:))+dy0);
	dx0 = Nl*dx/20;
	yM = x0 + (Nl-1)*dx + dx0;
	ym = x0 - dx0;
	axis([xm xM ym yM])
	
	ymark = get(gca,'YTick');
	yl = length(ymark);
	yspace = ymark(yl)-ymark(1);
	if (vecl(Nl)-ymark(yl))*yl*5<yspace
	    ymark(yl) = vecl(Nl);
	else
	    ymark = [ymark vecl(Nl)];
	end
	if (ymark(1)-vecl(1))*yl*5<yspace
	    ymark(1) = vecl(1);
	else
	    ymark = [vecl(1) ymark];
	end
		
	xmark = get(gca,'XTick');
	xmark = xmark(1:sum(xmark<vecc(Nc)));
	xl = length(xmark);
	xspace = xmark(xl)-xmark(1);
	if (vecc(Nc)-xmark(xl))*xl*3.5<xspace
	    xmark(xl) = vecc(Nc);
	else
	    xmark = [xmark vecc(Nc)];
	end
	if (xmark(1)-vecc(1))*xl*3.5<xspace
	    xmark(1) = vecc(1);
	else
	    xmark = [vecc(1) xmark];
	end

	plot([xmark;xmark],[ym;yM],'w:')
	plot([xm;xM],[ymark;ymark],'w:')
	set(gca,'ydir','reverse','XTick',xmark,'YTick',ymark)
	hold off
end
return
