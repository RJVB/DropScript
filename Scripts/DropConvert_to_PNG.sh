#! /usr/bin/perl -w

foreach (@ARGV) {
	$was = $_;
	if (`sips -s format png -i '$_'`) {
		s/\.(tiff?|jpe?g|gif|pdf|png|pict)$//;
		$_ .= ".png";
		if (-e $_) { warn "Could not rename file $was to $_ because it already exists.\n"; }
		else { rename ($was,$_) unless $was eq $_; }
	}
}
