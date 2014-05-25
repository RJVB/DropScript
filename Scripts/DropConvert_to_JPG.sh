#! /usr/bin/perl -w

foreach (@ARGV) {
	$was = $_;
	if (`sips -s format jpeg -i '$_'`) {
		s/\.(tiff?|jpe?g|gif|pdf|png|pict)$//;
		$_ .= ".jpg";
		if (-e $_) { warn "Could not rename file $was to $_ because it already exists.\n"; }
		else { rename ($was,$_) unless $was eq $_; }
	}
}
