require 'bio-statsample-glm/regression/poisson'
require 'bio-statsample-glm/regression/logistic'
module Statsample
  module Regression
    include Statsample::VectorShorthands

    # = Generalized linear models
    # == Parameters
    #
    # * x = model matrix
    # * y = response vector
    # * method = symbol; choice of glm strategy, default = :poisson
    #
    # == Usage
    #    require 'bio-statsample-glm'
    #    x1=Statsample::Vector.new([0.537322309644812,-0.717124209978434,-0.519166718891331,0.434970973986765,-0.761822002215759,1.51170030921189,0.883854199811195,-0.908689798854196,1.70331977539793,-0.246971150634099,-1.59077593922623,-0.721548040910253,0.467025703920194,-0.510132788447137,0.430106510266798,-0.144353683251536,-1.54943800728303,0.849307651309298,-0.640304240933579,1.31462478279425,-0.399783455165345,0.0453055645017902,-2.58212161987746,-1.16484414309359,-1.08829266466281,-0.243893919684792,-1.96655661929441,0.301335373291024,-0.665832694463588,-0.0120650855753837,1.5116066367604,0.557300353673344,1.12829931872045,0.234443748015922,-2.03486690662651,0.275544751380246,-0.231465849558696,-0.356880153225012,-0.57746647541923,1.35758352580655,1.23971669378224,-0.662466275100489,0.313263561921793,-1.08783223256362,1.41964722846899,1.29325100940785,0.72153880625103,0.440580131022748,0.0351917814720056, -0.142353224879252],:scale)
    #    x2=Statsample::Vector.new([-0.866655707911859,-0.367820249977585,0.361486610435,0.857332626245179,0.133438466268095,0.716104533073575,1.77206093023382,-0.10136697295802,-0.777086491435508,-0.204573554913706,0.963353531412233,-1.10103024900542,-0.404372761837392,-0.230226345183469,0.0363730246866971,-0.838265540390497,1.12543549657924,-0.57929175648001,-0.747060244805248,0.58946979365152,-0.531952663697324,1.53338594419818,0.521992029051441,1.41631763288724,0.611402316795129,-0.518355638373296,-0.515192557101107,-0.672697937866108,1.84347042325327,-0.21195540664804,-0.269869371631611,0.296155694010096,-2.18097898069634,-1.21314663927206,1.49193669881581,1.38969280369493,-0.400680808117106,-1.87282814976479,1.82394870451051,0.637864732838274,-0.141155946382493,0.0699950644281617,1.32568550595165,-0.412599258349398,0.14436832227506,-1.16507785388489,-2.16782049922428,0.24318371493798,0.258954871320764,-0.151966534521183],:scale)
    #    y=Statsample::Vector.new([0,0,1,0,1,1,1,1,0,1,1,1,1,0,1,0,1,1,0,1,0,1,1,1,1,0,0,1,1,0,0,1,0,0,1,1,0,0,1,1,0,1,1,1,1,0,0,0,1,1],:scale)
    #    x=Statsample::Dataset.new({"i"=>intercept,"x1"=>x1,"x2"=>x2})
    #    obj = Statsample::Regression.glm(x, y, :binomial)
    #    #=> Logistic Regression object
    #
    # == Returns
    #    GLM object for given method.
    def self.glm(x, y, method=:gaussian)
    
      if method.downcase.to_sym == :poisson
        obj = Statsample::Regression::GLM::Poisson.new(x,y)
      elsif method.downcase.to_sym == :binomial
        obj = Statsample::Regression::GLM::Logistic.new(x,y)
      else
        raise("Not implemented yet")
      end
      obj.irwls
      obj
    end


    def self.irwls(x, y, mu, w, j, h, epsilon = 1e-7, max_iter = 100)
      b = Matrix.column_vector(Array.new(x.column_size,0.0))
      converged = false
      1.upto(max_iter) do |i|
        #conversion from : (solve(j(x,b)) %*% h(x,b,y))

        intermediate = (j.call(x,b).inverse * h.call(x,b,y))
        b_new = b - intermediate

        if((b_new - b).map(&:abs)).to_a.flatten.inject(:+) < epsilon
          converged = true
          b = b_new
          break
        end
        b = b_new
      end
      ss = j.call(x,b).inverse.diagonal.map{ |x| -x}.map{ |y| Math.sqrt(y) }
      values = mu.call(x,b)

      residuals = y - values.column_vectors.map(&:to_a).flatten
      df_residuals = y.count - x.column_size
      return [create_vector(b.column_vectors[0]), create_vector(ss), create_vector(values.to_a.flatten),
              residuals, max_iter, df_residuals, converged]
    end

    private
    def self.create_vector(arr)
      Statsample::Vector.new(arr, :scale)
    end
  end
end
