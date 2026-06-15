#set page(
  paper: "us-letter",
  numbering: "1/1",
  columns: 2,
)
#set text(
  font: "Times New Roman",
  size: 9pt,
)
#show heading: set text(size: 9pt)
#show heading: set block(below: 1em, above: 1.5em)
#show heading.where(level: 2): it => text(weight: "regular")[#emph(it)]
#set par(
  justify: true,
)
#show title: set block(below: 1.2em)
#show title: set text(size: 11pt)
#set math.equation(
  numbering: "(1)",
)

// Define authors and affiliations
#let authors = (
  (
    name: "Santiago Soler*",
    orcid: "0000-0001-9202-5317",
    affiliation: "ubc",
  ),
  (
    name: "Joseph Capriotti",
    orcid: "0000-0003-4762-5377",
    affiliation: "mines",
  ),
   (
    name: "Johnathan Kuttai",
    orcid: "0009-0006-6356-944X",
    affiliation: "ubc",
  ),
  (
    name: "Lindsey Heagy",
    orcid: "0000-0002-1551-5926",
    affiliation: "ubc",
  )
)
#let affiliations = (
  ubc: (id: "1", name: "University of British Columbia"),
  mines: (id: "2", name: "Colorado School of Mines"),
)

#let print_author(author) = {
  // Print author name with their affiliation and ORCID link
  author.name
  super(affiliations.at(author.affiliation).id)
  link("https://orcid.org/" + author.orcid)[#box(height: 0.8em, baseline:
  13.5%)[#image("orcid.svg")]]
}

#place(
  top,
  float: true,
  scope: "parent",
)[

  #title[
    On the redesign of SimPEG's inversion framework
  ]

  // List authors
  #align(left)[
    #set text(size: 10pt, style: "italic")
    #authors.map(author => {print_author(author)}).join(", ", last: ", and ") \
    #for (key, affiliation) in affiliations [
      #super(affiliation.id)#affiliation.name,
    ]
    #link("mailto:ssoler@eoas.ubc.ca")
  ]
]

// set links in blue
#show link: set text(blue)

#let class(name) = {
  text(fill: purple)[#raw(name)]
}
#let function(name) = {
  text(fill: blue)[#raw(name)]
}


= Summary

// Max 1000 characters (same as the summary we'll include in the online form)

We present a prototype for a new inversion framework for SimPEG: an open-source Python library to run simulations and inversions.
The redesign is motivated by our experience experimenting with newer inversion styles, such as joint inversions, machine learning techniques, and alternative optimizers.
We ran into rigid assumptions in the existing framework, and we aim to improve the interface to support this work.
The new prototype is aimed to be more modular, extensible, flexible and easier to read, with the ultimate goal of facilitating new research avenues and ease its use for practitioners in mineral exploration.




= Introduction

SimPEG is an open-source Python library that supports simulations and inversions of many geophysical surveys such as gravity and magnetics, resistivity (DC), induced polarization (IP), time and frequency domain electromagnetic data with controlled or natural sources, and more.
It was started over a decade ago with the aim of being a modular and extensible toolbox for research and resource exploration.
Since then, SimPEG has become widely used by researchers and industry professionals, who rely on it for generating reproducible and transparent workflows.

Newer research methods such as in joint inversions, in leveraging aspects of machine learning, and in new optimization algorithms exposed areas where the initial framework had made some rigid assumptions.
These assumptions imposed some barriers for users trying to implement such new methods with SimPEG, and forced them to develop complex solutions to circumvent these difficulties.

In this work, we present a prototype for a redesign of SimPEG’s inversion framework that supports this next generation of research by improving its design, usability, extensibility, and code readability.
Its final goal is to facilitate new research avenues by allowing users to easily interact with and extend the framework.


= New design for the inversion framework

The main goal of the redesign is to create a more modular, extensible, and flexible inversion framework that can be easily applied to a broader set of use cases.
We also aim to generate a clean codebase that is easy to read, which also makes the code easier to study and learn from.

A generalized deterministic inversion problem can be defined as the minimization of an objective function :

$ limits("min")_bold(m)" "phi.alt(bold(m)), $ <inversion>

where $bold(m)$ is the _model_ vector that contains the parameters we want to invert for.

In the classical form, the objective function is defined as a linear combination of a _data misfit_ term $phi.alt_d (bold(m))$ that provides a metric of how well a given model fits the observed data, and a _model norm_ term $phi.alt_m (bold(m))$ that imposes a-priori information on the model:

$ phi.alt(bold(m)) = phi.alt_d (bold(m)) + beta phi.alt_m (bold(m)), $ <classic_objective>

where $beta$ is the _trade-off parameter_.
Although many geophysical inversions can be described by @classic_objective, many others don’t follow that form: e.g. parametric inversions that don’t require model norm terms, inversions based on a primal-dual formulation that involve minimization in different functional spaces.

The new inversion framework is composed mainly of three parts: the _objective function_ that will be minimized, the _minimizer_ that will be used to iteratively find a minimum of the objective function, and a new #class("Inversion") class that configures and brings together a full inversion.


== Objective function

The new framework requires every objective function to be a child of a base #class("Objective") abstract class, so that it behaves similarly to the mathematical analog: when _called_ it takes a model array and returns a single real value.
It also implements methods for the first and second derivatives of the objective function for a given model array (#function("gradient") and #function("hessian")).

Objective functions can be multiplied by scalars and added together, allowing users to create any arbitrary linear combination of a set of objective functions.
The #class("Objective") base class doesn’t impose any rigid assumption on the inner workings of its children, only on the interface of its base methods.
This enables users to define a wide range of objective functions: from a classical form like the one in @classic_objective, to any other possible linear combination.

== Minimizer

The minimization of the objective function is handled by a minimizer object.
It can be a simple Python function that takes the objective function to be minimized and the initial model, and returns the inverted model.
For example, SciPy functions like #function("scipy.optimize.minimize") and #function("scipy.sparse.linalg.cg") can be used directly with the new objective function object.

Alternatively, a minimizer can also be an object we can iterate over when _called_.
This enables users to insert custom code in between the iterations to check intermediate results, plot them, and save them to files without the need to modify the minimizer itself.

The new framework offers some built-in minimizers like a conjugate gradient function and a Gauss-Newton conjugate gradient class, designed for linear and non-linear inversions, respectively.

== The Inversion class

During the minimization process described in @inversion, the objective function $phi.alt(bold(m))$ is left unchanged.
Nonetheless, several inversion techniques involve modifying hyperparameter values algorithmically.
For example, using a beta-cooling strategy, or updating parameters in an iteratively re-weighted least squares approach.
Moreover, any inversion process needs a _stopping criterion_, i.e. a condition, that when met causes the inversion to stop.
For example, if the data misfit reaches a certain target.

These steps introduce some complexity into the inversion process, that can be summarized as:

+ Minimize the objective function.
+ Check if the stopping criterion is satisfied.
+ Modify objective function's hyperparameters.
+ Go to the first step.

The new inversion framework ships a #class("Inversion") class that configures a full inversion process by taking: the initial objective function that will be minimized, the minimizer that will be used, the initial model of the inversion, the stopping criterion, and a set of _directives_ as functions that perform actions after each iteration (e.g. modifying the objective function’s hyperparameters).

The #class("Inversion") object can also be iterated over, enabling users to introduce intermediate steps after each iteration like visualizing results.
Users can also pause the inversion process and resume it later, creating a more interactive experience.

The stopping criterion that the #class("Inversion") class takes can be a simple function that returns a _boolean_ upon a condition for the current model array, or it can be a #class("Condition") object, that allow to add more complexity to such conditions.
#class("Condition") objects can be combined through `AND` , `OR` and `XOR` logical binary operators to create a single stopping criterion object that can be passed to the #class("Inversion").

The stopping criterion that the #class("Inversion") class takes can be a simple function that returns a _boolean_ upon a condition for the current model array, or it can be a #class("Condition") object, that allows users to add more complexity.
#class("Condition") objects can be combined through logical binary operators to create a single stopping criterion object that can be passed to the Inversion.

The #class("Inversion") object can also produce an _inversion log_, as a table that is printed to the user to provide information about each iteration.
The inversion log can be easily customized, or even replaced entirely by a user-defined one.


== Example

Here we show a simple example on how to run a 2D DC-IP inversion with a _beta cooling_ technique using the new inversion framework.

```python
# Define the objective function
# -----------------------------
# Define the data misfit for a 2D DC-IP simulation.
data_misfit = DataMisfit(
    data, uncertainty, dcip_simulation
)
# Define a model norm term with a smallness
# and two flatness terms.
model_norm = (
    Smallness(mesh)
    + 0.2 * Flatness(mesh, direction="x")
    + 0.2 * Flatness(mesh, direction="y")
)
# Initial value for the trade-off parameter.
beta = 1e6
# Define the objective function.
phi = data_misfit + beta * model_norm

# Define the inversion
# --------------------
# Define a stopping criterion as a chi factor of 1.
stopping_criterion = ChiTarget(
    data_misfit, chi_target=1.0
)
# Directive to cool down beta after each iteration.
beta_cooler = MultiplierCooler(model_norm)
# Define the inversion.
inversion = Inversion(
    phi,
    initial_model,
    minimizer=GaussNewtonConjugateGradient(),
    directives=[beta_cooler],
    stopping_criterion=stopping_criterion,
)

# Run the inversion
# -----------------
for model in inversion:
    # Print some information between iterations.
    print(f"Iteration {inversion.counter}")
    print(f"  - Data misfit: {data_misfit(model)}")
# Last model is the inverted one
inverted_model = model
```

= Conclusions

We have created a prototype of SimPEG’s new inversion framework that is more modular, extensible, flexible, and interactive.
The prototype is available at https://github.com/simpeg/inversion-design-ideas under the open-source MIT License.
Our goal is to progressively incorporate it into SimPEG in the near future: first as an experimental submodule, and then make it the preferred way to run inversions.
We invite everyone to experiment with it and provide feedback.
