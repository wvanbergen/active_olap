class ActiveOLAP::Dimension::TimestampSnapshot < ActiveOLAP::Dimension
  
  attr_accessor :lower_bound_expression, :upper_bound_expression, :other_constraints

  def requires_unions?
    true
  end
end
