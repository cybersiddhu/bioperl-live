
=head1 NAME

Bio::Matrix::PSM::SiteMatrix - SiteMatrixI implementation, holds a
position scoring matrix (or position weight matrix) and log-odds

=head1 SYNOPSIS

  use Bio::Matrix::PSM::SiteMatrix;
  # Create from memory by supplying probability matrix hash
  # both as strings or arrays
  # where the frequencies  $a,$c,$g and $t are supplied either as
  # arrayref or string. Accordingly, lA, lC, lG and lT are the log
  # odds (only as arrays, no checks done right now)
  my ($a,$c,$g,$t,$score,$ic, $mid)=@_;
  #or
  my ($a,$c,$g,$t,$score,$ic,$mid)=('05a011','110550','400001',
                                    '100104',0.001,19.2,'CRE1');
  #Where a stands for all (this frequency=1), see explanation bellow
  my %param=(-pA=>$a,-pC=>$c,-pG=>$g,-pT=>$t,
             -lA=>$la, -lC=>$lc,-lG=>$lg,-lT=>$l,
             -IC=>$ic,-e_val=>$score, -id=>$mid);
  my $site=new Bio::Matrix::PSM::SiteMatrix(%param);
  #Or get it from a file:
  use Bio::Matrix::PSM::IO;
  my $psmIO= new Bio::Matrix::PSM::IO(-file=>$file, -format=>'transfac');
  while (my $psm=$psmIO->next_psm) {
    #Now we have a Bio::Matrix::PSM::Psm object,
    # see Bio::Matrix::PSM::PsmI for details
    #This is a Bio::Matrix::PSM::SiteMatrix object now
    my $matrix=$psm->matrix;
  }

  # Get a simple consensus, where alphabet is {A,C,G,T,N},
  # choosing the highest probability or N if prob is too low
  my $consensus=$site->consensus;

  #Getting/using regular expression
  my $regexp=$site->regexp;
  my $count=grep($regexp,$seq);
  my $count=($seq=~ s/$regexp/$1/eg);
  print "Motif $mid is present $count times in this sequence\n";

=head1 DESCRIPTION

SiteMatrix is designed to provide some basic methods when working with
position scoring (weight) matrices, such as transcription factor
binding sites for example.  A DNA PSM consists of four vectors with
frequencies {A,C,G,T). This is the minimum information you should
provide to construct a PSM object. The vectors can be provided as
strings with frequencies where the frequency is {0..a} and a=1. This
is the way MEME compressed representation of a matrix and it is quite
useful when working with relational DB.  If arrays are provided as an
input (references to arrays actually) they can be any number, real or
integer (frequency or count).

When creating the object the constructor will check for positions that
equal 0.  If such is found it will increase the count for all
positions by one and recalculate the frequency.  Potential bug- if you
are using frequencies and one of the positions is 0 it will change
significantly.  However, you should never have frequency that equals
0.

Throws an exception if: You mix as an input array and string (for
example A matrix is given as array, C - as string).  The position
vector is (0,0,0,0).  One of the probability vectors is shorter than
the rest.

Summary of the methods I use most frequently (details bellow):

  iupac - return IUPAC compliant consensus as a string
  score - Returns the score as a real number
  IC - information content. Returns a real number
  id - identifier. Returns a string
  accession - accession number. Returns a string
  next_pos - return the sequence probably for each letter, IUPAC
      symbol, IUPAC probability and simple sequence
  consenus letter for this position. Rewind at the end. Returns a hash.
  pos - current position get/set. Returns an integer.
  regexp - construct a regular expression based on IUPAC consensus.
      For example AGWV will be [Aa][Gg][AaTt][AaCcGg]
  width - site width
  get_string - gets the probability vector for a single base as a string.
  get_array - gets the probability vector for a single base as an array.
  get_logs_array - gets the log-odds vector for a single base as an array.

New methods, which might be of interest to anyone who wants to store PSM in a relational
database without creating an entry for each position is the ability to compress the
PSM vector into a string with losing usually less than 1% of the data.
this can be done with:

  my $str=$matrix->get_compressed_freq('A');

or

  my $str=$matrix->get_compressed_logs('A');

Loading from a database should be done with new, but is not yest implemented.
However you can still uncompress such string with:

  my @arr=Bio::Matrix::PSM::_uncompress_string ($str,1,1); for PSM

or

  my @arr=Bio::Matrix::PSM::_uncompress_string ($str,1000,2); for log odds

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  bioperl-l@bioperl.org                 - General discussion
  http://bio.perl.org/MailList.html     - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via email
or the web:

  bioperl-bugs@bio.perl.org
  http://bugzilla.bioperl.org/

=head1 AUTHOR - Stefan Kirov

Email skirov@utk.edu

=head1 APPENDIX

=cut


# Let the code begin...

package Bio::Matrix::PSM::SiteMatrixI;

use Bio::Root::RootI;
use vars qw(@ISA);
# use strict;
@ISA=qw(Bio::Root::RootI);


=head2 new

 Title   : new
 Usage   : my $site=new Bio::Matrix::PSM::SiteMatrix
              (-pA=>$a,-pC=>$c,-pG=>$g,-pT=>$t,
               -IC=>$ic,-e_val=>$score, -id=>$mid);
 Function: Creates a new Bio::Matrix::PSM::SiteMatrix object from memory
 Throws  : If inconsistent data for all vectors (A,C,G and T) is provided,
           if you mix input types (string vs array) or if a position freq is 0.
 Example :
 Returns : Bio::Matrix::PSM::SiteMatrix object
 Args    : hash


=cut

sub new {
  my $self = shift;
  $self->throw_not_implemented();
}

=head2 _initialize

 Title   : _initialize
 Usage   : my $site=$matrix->_initialize
              (-pA=>$a,-pC=>$c,-pG=>$g,-pT=>$t,
               -lA=>$la,-lC=>$lc,-lG=>$lg,-lT=>$lt,
               -IC=>$ic,-e_val=>$score, -id=>$mid);
 Function: Initialize an empty Bio::Matrix::PSM::SiteMatrix object
 Throws  : If inconsistent data for all vectors (A,C,G and T) is provided,
           if you mix input types (string vs array) or if a position freq is 0.
 Example :
 Returns : Bio::Matrix::PSM::SiteMatrix object
 Args    : hash


=cut

sub _initialize {
  my $self = shift;
  $self->throw_not_implemented();
}

=head2 next_pos

 Title   : next_pos
 Usage   : my %base=$site->next_pos;
 Function: 

           Retrieves the next position features: frequencies for
           A,C,G,T, the main letter (as in consensus) and the
           probabilty for this letter to occur at this position and
           the current position

 Throws  :
 Example :
 Returns : hash (pA,pC,pG,pT,base,prob,rel)
 Args    : none


=cut

sub next_pos {
  my $self = shift;
  $self->throw_not_implemented();
}

=head2 curpos

 Title   : curpos
 Usage   : my $pos=$site->curpos;
 Function: Gets/sets the current position. Converts to 0 if argument is minus and
            to width if greater than width
 Throws  :
 Example :
 Returns : integer
 Args    : integer

=cut

sub curpos {
    my $self = shift;
   $self->throw_not_implemented();
}

=head2 e_val

 Title   : e_val
 Usage   : my $score=$site->e_val;
 Function: Gets/sets the e-value
 Throws  :
 Example :
 Returns : real number
 Args    : real number

=cut

sub e_val {
    my $self = shift;
    $self->throw_not_implemented();
}

=head2 consensus

 Title   : consensus
 Usage   :  my $strict=$matrix->consensus(8);
 Function: Returns the consensus
 Throws  : if supplied with thresold outisde 5..10 range
 Example :
 Returns : string
 Args    : (optional) threshold value 5 to 10

=cut

sub consensus {
  my $self = shift;
  $self->throw_not_implemented();
}

=head2 accession_number

 Title   : accession_number
 Usage   :
 Function: accession number, this will be unique id for the SiteMatrix object as
 			well for any other object, inheriting from SiteMatrix
 Throws  :
 Example :
 Returns : string
 Args    : string

=cut

sub accession_number {
  my $self = shift;
  $self->throw_not_implemented();
}


=head2 width

 Title   : width
 Usage   : my $width=$site->width;
 Function: Returns the length of the site
 Throws  :
 Example :
 Returns : number
 Args    :

=cut

sub width {
  my $self = shift;
  $self->throw_not_implemented();
}

=head2 IUPAC

 Title   : IUPAC
 Usage   : my $iupac_consensus=$site->IUPAC;
 Function: Returns IUPAC compliant consensus
 Throws  :
 Example :
 Returns : string
 Args    :

=cut

sub IUPAC {
  my $self = shift;
  $self->throw_not_implemented();
}

=head2 IC

 Title   : IC
 Usage   : my $ic=$site->IC;
 Function: Information content
 Throws  :
 Example :
 Returns : real number
 Args    : none

=cut

sub IC {
my $self=shift;
$self->throw_not_implemented();
}

=head2 get_string

 Title   : get_string
 Usage   : my $freq_A=$site->get_string('A');
 Function: Returns given probability vector as a string. Useful if you want to
           store things in a rel database, where arrays are not first choice
 Throws  : If the argument is outside {A,C,G,T}
 Example :
 Returns : string
 Args    : character {A,C,G,T}

=cut

sub get_string {
 my $self=shift;
 $self->throw_not_implemented();
}

=head2 id

 Title   : id
 Usage   : my $id=$site->id;
 Function: Gets/sets the site id
 Throws  :
 Example :
 Returns : string
 Args    : string

=cut

sub id {
    my $self = shift;
    $self->throw_not_implemented();
}

=head2 regexp

 Title   : regexp
 Usage   : my $regexp=$site->regexp;
 Function: Returns a regular expression which matches the IUPAC convention.
           N will match X, N, - and .
 Throws  :
 Example :
 Returns : string
 Args    :

=cut

sub regexp {
 my $self=shift;
 $self->throw_not_implemented();
}

=head2 regexp_array

 Title   : regexp_array
 Usage   : my @regexp=$site->regexp;
 Function: Returns a regular expression which matches the IUPAC convention.
           N will match X, N, - and .
 Throws  :
 Example :
 Returns : array
 Args    :
 To do   : I have separated regexp and regexp_array, but
           maybe they can be rewritten as one - just check what
           should be returned

=cut

sub regexp_array {
 my $self=shift;
 $self->throw_not_implemented();
}

=head2 get_array

 Title   : get_array
 Usage   : my @freq_A=$site->get_array('A');
 Function: Returns an array with frequencies for a specified base
 Throws  :
 Example :
 Returns : array
 Args    : char

=cut

sub get_array {
  my $self=shift;
  $self->throw_not_implemented();
}


=head2 _to_IUPAC

 Title   : _to_IUPAC
 Usage   :
 Function: Converts a single position to IUPAC compliant symbol and
            returns its probability. For rules see the implementation.
 Throws  :
 Example :
 Returns : char, real number
 Args    : real numbers for A,C,G,T (positional)

=cut

sub _to_IUPAC {
    my $self = shift;
    $self->throw_not_implemented();
}

=head2 _to_cons

 Title   : _to_cons
 Usage   :
 Function: Converts a single position to simple consensus character and
            returns its probability. For rules see the implementation,
 Throws  :
 Example :
 Returns : char, real number
 Args    : real numbers for A,C,G,T (positional)

=cut

sub _to_cons {
    my $self = shift;
    $self->throw_not_implemented();
}


=head2 _calculate_consensus

 Title   : _calculate_consensus
 Usage   :
 Function: Internal stuff
 Throws  :
 Example :
 Returns :
 Args    :

=cut

sub _calculate_consensus {
    my $self = shift;
    $self->throw_not_implemented();
}

=head2 _compress_array

 Title   : _compress_array
 Usage   :
 Function:  Will compress an array of real signed numbers to a string (ie vector of bytes)
 			-127 to +127 for bi-directional(signed) and 0..255 for unsigned ;
 Throws  :
 Example :  Internal stuff
 Returns :  String
 Args    :  array reference, followed by an max value and
 			direction (optional, default 1-unsigned),1 unsigned, any other is signed.

=cut

sub _compress_array {
    my $self = shift;
    $self->throw_not_implemented();
}

=head2 _uncompress_string

 Title   : _uncompress_string
 Usage   :
 Function:  Will uncompress a string (vector of bytes) to create an array of real
            signed numbers (opposite to_compress_array)
 Throws  :
 Example :  Internal stuff
 Returns :  string, followed by an max value and
 			direction (optional, default 1-unsigned), 1 unsigned, any other is signed.
 Args    :  array

=cut

sub _uncompress_string {
    my $self = shift;
    $self->throw_not_implemented();
}

=head2 get_compressed_freq

 Title   : get_compressed_freq
 Usage   :
 Function:  A method to provide a compressed frequency vector. It uses one byte to
 			code the frequence for one of the probability vectors for one position.
			Useful for relational database. Improvment of the previous 0..a coding.
 Throws  :
 Example :  my $strA=$self->get_compressed_freq('A');
 Returns :  String
 Args    :  char

=cut

sub get_compressed_freq {
    my $self = shift;
    $self->throw_not_implemented();
}

=head2 get_compressed_logs

 Title   : get_compressed_logs
 Usage   :
 Function:  A method to provide a compressed log-odd vector. It uses one byte to
 			code the log value for one of the log-odds vectors for one position.
 Throws  :
 Example :  my $strA=$self->get_compressed_logs('A');
 Returns :  String
 Args    :  char

=cut

sub get_compressed_logs {
    my $self = shift;
    $self->throw_not_implemented();
}

=head2 sequence_match_weight

 Title   : sequence_match_weight
 Usage   :
 Function:  This method will calculate the score of a match, based on the PWM
            if such is associated with the matrix object. Returns undef if no
             PWM data is available.
 Throws  :   if the length of the sequence is different from the matrix width
 Example :  my $score=$matrix->sequence_match_weight('ACGGATAG');
 Returns :  Floating point
 Args    :  string

=cut

sub sequence_match_weight {
    my $self = shift;
    $self->throw_not_implemented();
}


1;
