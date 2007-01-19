# $Id$
#
# BioPerl module for Bio::Align::Utilities
#
# Cared for by Jason Stajich <jason-at-bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::Align::Utilities - A collection of utilities regarding converting
and manipulating alignment objects

=head1 SYNOPSIS

  use Bio::Align::Utilities qw(:all);
  # %dnaseqs is a hash of CDS sequences (spliced)


  # Even if the protein alignments are local make sure the start/end
  # stored in the LocatableSeq objects are to the full length protein.
  # The CoDing Sequence that is passed in should still be the full 
  # length CDS as the nt alignment will be generated.
  #
  my $dna_aln = &aa_to_dna_aln($aa_aln,\%dnaseqs);


  # generate bootstraps
  my $replicates = &bootstrap_replicates($aln,$count);


=head1 DESCRIPTION

This module contains utility methods for manipulating sequence
alignments ( L<Bio::Align::AlignI>) objects.

The B<aa_to_dna_aln> utility is essentially the same as the B<mrtrans>
program by Bill Pearson available at
ftp://ftp.virginia.edu/pub/fasta/other/mrtrans.shar.  Of course this
is a pure-perl implementation, but just to mention that if anything
seems odd you can check the alignments generated against Bill's
program.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Jason Stajich

Email jason-at-bioperl-dot-org

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

#' keep my emacs happy
# Let the code begin...


package Bio::Align::Utilities;
use vars qw(@EXPORT @EXPORT_OK $GAP $CODONGAP %EXPORT_TAGS);
use strict;
use Carp;
use Bio::Root::Version;
require Exporter;

use base qw(Exporter);

@EXPORT = qw();
@EXPORT_OK = qw(aa_to_dna_aln bootstrap_replicates bracket_string);
%EXPORT_TAGS = (all =>[@EXPORT, @EXPORT_OK]);
BEGIN {
    use constant CODONSIZE => 3;
    $GAP = '-';
    $CODONGAP = $GAP x CODONSIZE;
}

=head2 aa_to_dna_aln

 Title   : aa_to_dna_aln
 Usage   : my $dnaaln = aa_to_dna_aln($aa_aln, \%seqs);
 Function: Will convert an AA alignment to DNA space given the 
           corresponding DNA sequences.  Note that this method expects 
           the DNA sequences to be in frame +1 (GFF frame 0) as it will
           start to project into coordinates starting at the first base of 
           the DNA sequence, if this alignment represents a different 
           frame for the cDNA you will need to edit the DNA sequences
           to remove the 1st or 2nd bases (and revcom if things should be).
 Returns : Bio::Align::AlignI object 
 Args    : 2 arguments, the alignment and a hashref.
           Alignment is a Bio::Align::AlignI of amino acid sequences. 
           The hash reference should have keys which are 
           the display_ids for the aa 
           sequences in the alignment and the values are a 
           Bio::PrimarySeqI object for the corresponding 
           spliced cDNA sequence. 

See also: L<Bio::Align::AlignI>, L<Bio::SimpleAlign>, L<Bio::PrimarySeq>

=cut

sub aa_to_dna_aln {
    my ($aln,$dnaseqs) = @_;
    unless( defined $aln && 
	    ref($aln) &&
	    $aln->isa('Bio::Align::AlignI') ) { 
	croak('Must provide a valid Bio::Align::AlignI object as the first argument to aa_to_dna_aln, see the documentation for proper usage and the method signature');
    }
    my $alnlen = $aln->length;
    my $dnaalign = new Bio::SimpleAlign;
    $aln->map_chars('\.',$GAP);

    foreach my $seq ( $aln->each_seq ) {    
	my $aa_seqstr = $seq->seq();
	my $id = $seq->display_id;
	my $dnaseq = $dnaseqs->{$id} || $aln->throw("cannot find ".
						     $seq->display_id);
	my $start_offset = ($seq->start - 1) * CODONSIZE;

	$dnaseq = $dnaseq->seq();
	my $dnalen = $dnaseqs->{$id}->length;
	my $nt_seqstr;
	my $j = 0;
	for( my $i = 0; $i < $alnlen; $i++ ) {
	    my $char = substr($aa_seqstr,$i + $start_offset,1);	    
	    if ( $char eq $GAP || $j >= $dnalen )  { 
		$nt_seqstr .= $CODONGAP;
	    } else {
		$nt_seqstr .= substr($dnaseq,$j,CODONSIZE);
		$j += CODONSIZE;
	    }
	}
	$nt_seqstr .= $GAP x (($alnlen * 3) - length($nt_seqstr));

	my $newdna = new Bio::LocatableSeq(-display_id  => $id,
					   -alphabet    => 'dna',
					   -start       => $start_offset+1,
					   -end         => ($seq->end * 
							    CODONSIZE),
					   -strand      => 1,
					   -seq         => $nt_seqstr);    
	$dnaalign->add_seq($newdna);
    }
    return $dnaalign;
}

=head2 bootstrap_replicates

 Title   : bootstrap_replicates
 Usage   : my $alns = &bootstrap_replicates($aln,100);
 Function: Generate a pseudo-replicate of the data by randomly
           sampling, with replacement, the columns from an alignment for
           the non-parametric bootstrap.
 Returns : Arrayref of L<Bio::SimpleAlign> objects
 Args    : L<Bio::SimpleAlign> object
           Number of replicates to generate

=cut

sub bootstrap_replicates {
   my ($aln,$count) = @_;
   $count ||= 1;
   my $alen = $aln->length;
   my (@seqs,@nm);
   $aln->set_displayname_flat(1);
   for my $s ( $aln->each_seq ) {
       push @seqs, $s->seq();
       push @nm, $s->id;
   }
   my (@alns,$i);
   while( $count-- > 0 ) {
       my @newseqs;
       for($i =0; $i < $alen; $i++ ) {
	   my $index = int(rand($alen));
	   my $c = 0;
	   for ( @seqs ) {
	       $newseqs[$c++] .= substr($_,$index,1);
	   }
       }
       my $newaln = Bio::SimpleAlign->new();
       my $i = 0;
       for my $s ( @newseqs ) {

	   $newaln->add_seq( Bio::LocatableSeq->new
			     (-start         => 1,
			      -end           => $alen,
			      -display_id    => $nm[$i++],
			      -seq           => $s));
       }
       push @alns, $newaln;
   }
   return \@alns;
}

=head2 bracket_string

 Title     : bracket_string
 Usage     : $str = $ali->bracket_string()
 Function  : creates a bracketed consensus-like string for an alignment.  This
             string contains all residues (including gaps, ambiguities, etc.)
             from all alignment sequences.  Where ambiguities are present in
             a column, residues for each sequence are represented (in alignment
             order) in order in brackets.
             
             Apparently this is called BCI format.
             
             So, for these sequences:
            
             >seq1
             GGATCCATTCCTACT
             >seq2
             GGAT--ATTCCTCCT
            
             You would get this string:
            
             GGAT[C/-][C/-]ATTCCT[A/C]CT
              
             Note that this will be very noisy with protein sequences or
             alignments with lots of sequences.  Use with care!
             
 Returns   : string
 Argument  : none

=cut

sub bracket_string {
    my $aln = shift;
    my $out = "";
    my $len = $aln->length-1;
    # loop over the alignment columns
    foreach my $count ( 0 .. $len ) {
        $out .= _bracket_string($aln, $count);
    }
    return $out;
}

sub _bracket_string {
    my ($aln, $column) = @_;
    my $string;
    my %bic;
    my @residues;
    #what residues are in the sequences
    foreach my $seq ( $aln->each_seq() ) {
        my $res = substr($seq->seq, $column, 1);
        push @residues, $res;
        $bic{$res}++;
    }
    # Are there more than one residue/gap in the column?
    $string = (scalar(keys %bic) > 1) ? '['.(join '/', @residues).']' :
              shift @residues;
    return $string;
}

1;
