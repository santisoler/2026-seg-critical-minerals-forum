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
The new framework has been motivated by extending the capabilities of SimPEG to latest research methods such as in joint inversions, in leveraging machine learning techniques, and in using new optimizers in inversions.
The new prototype is aimed to be more modular, extensible, flexible and easier to read, with the ultimate goal of facilitating new research avenues and ease its use for practitioners in mineral exploration.




= Introduction

// What's SimPEG.
// Motivations behind the redesign.
// General goals of the new design (modularity, extensibility, improve readability and ease of use).

SimPEG is an open-source Python library that supports simulations and inversions of many geophysical surveys such as gravity and magnetics, resistivity (DC), induced polarization (IP), time and frequency domain electromagnetic data with controlled or natural sources, and more.
It was created over a decade ago with the aim of being a modular and extensible toolbox for research and resource exploration.
Throughout the years, SimPEG became widely used by researchers and industry professionals, who relied on it for generating reproducible and transparent workflows.

Newer research methods such in joint inversions, in leveraging aspects of machine learning, and in new optimization algorithms exposed areas where the initial framework had made some rigid assumptions.
These assumptions imposed some barriers when trying to implement such new methods with SimPEG, and forced users to develop complex solutions to circumvent these difficulties.

In this work we present a prototype for a redesign of SimPEG's inversion framework that supports this next generation of research by improving its design, usability, extensibility, and code readability.
Its final goal is to facilitate new research avenues by allowing users to easily interact with and extend the framework.


// Maybe we need to add some link between the inversion framework and critical minerals exploration in the introduction. Maybe related to who is using SimPEG, or known cases, or why the new framework will facilitate the future exploration.

= New design for the inversion framework

// Goals of the new design
// - Create a more flexible framework that can be easily adapted to many use cases.

The main goal of the redesign is to create a more modular, extensible, and flexible inversion framework that can be easily applied to a broader set of use cases.
We also aim to generate a clean codebase that is easy to read, facilitating studying and learning the code.

// Parts of the framework:
//   - Objective function
//     - DataMisfit
//     - Regularizations
//   - Minimzer
//   - Inversion class

// Objective function

A generalized deterministic inversion problem can be defined as the minimization of an objective function $phi.alt(bold(m))$:

$ limits("min")_bold(m)" "phi.alt(bold(m)), $ <inversion>

where $bold(m)$ is the _model_ vector that contains the parameters we want to invert for.

In the classical form, the objective function is defined as a linear combination of a _data misfit_ term $phi.alt_d (bold(m))$ that provides a metric of how well a given model fits the observed data, and a _regularization_ term $phi.alt_m (bold(m))$ that imposes a-priori information on the model:

$ phi.alt(bold(m)) = phi.alt_d (bold(m)) + beta phi.alt_m (bold(m)), $ <classic_objective>

where $beta$ is the _trade-off parameter_.
Although many geophysical inversions can be described as in equation @classic_objective, many others don't follow that form: e.g. some parametric inversions that don't require regularization terms, inversions based on a primal-dual space that involve minimization in different functional spaces.

The new inversion framework is composed mainly by three parts: the _objective function_ that will be minimized, the _minimizer_ that will be used to iteratively find a minimum of the objective function, and a new #raw("Inversion") class that configures and groups together a full inversion.


== Objective function

The new framework requires every objective function to be a child of a base #class("Objective") abstract class that requires it to behave similarly to the mathematical analogous object: when _called_ it takes a model array and returns a single real value.
It also requires it to implement methods like #function("gradient") and #function("jacobian") that return the first and second derivatives of the objective function for a particular model array.

Objective functions can be multiplied by scalars and added together, allowing users to create any arbitrary linear combination of a set of objective functions.
The #class("Objective") base class doesn't impose any rigid assumption on the inner workings of its children, only on the interface of its base methods. This enables users to define a wide range of objective functions: from a classical form like the one in equation @classic_objective, to any other possible linear combination.

== Minimizer

The minimization of the objective function is taken care by a minimizer object. It can be a simple Python function that takes the objective function to be minimized and the initial model, and returns the inverted model. For example, SciPy functions like #function("scipy.optimize.minimize") and #function("scipy.sparse.linalg.cg") can be used directly with the new objective function object.

Alternatively, a minimizer can also be an object we can iterate over when _called_.
This enables users to insert custom code in between the iterations to check intermediate results, plot them, and save them to files without the need to modify the minimizer itself.

The new framework offers some built-in minimizers like a conjugate gradient function and a Gauss-Newton conjugate gradient class, designed for linear and non-linear inversions, respectively.

== The Inversion class

During the minimization process described in equation @inversion, the objective function $phi.alt(bold(m))$ is left unchanged.
Nonetheless, several inversion techniques involve the search of values for hyperparameters (like the trade-off parameter $beta$), or the update of certain parameters within the objective functions (e.g. iterative re-weighted least-squares) during the inversion process itself.
Moreover, any inversion process needs a _stopping criterion_, i.e. a condition that when met should force the inversion to stop. For example, if the observed data is recovered within a certain uncertainty.

These extra steps introduce some complexity into the inversion process, that can be summarized as:

+ Minimize the objective function. <firstitem>
+ Check if the stopping criterion is satisfied.
+ Modify objective function's hyperparameters.
+ Go to the first step.

The new inversion framework ships a #class("Inversion") class that can configure a full inversion process by taking: the initial objective function that will be minimized, the minimizer that will be used, the initial model of the inversion, the stopping criterion, and a set of _directives_ as functions that perform actions after each iteration (e.g. modifying the objective function's hyperparameters).

The #class("Inversion") object can also be iterated over, enabling users to introduce intermediate steps after each iteration like visualizing results.
Users can also pause the inversion process and resume it later, creating a more interactive experience.

The stopping criterion that the #class("Inversion") class takes can be a simple function that returns a _boolean_ upon a condition for the current model array, or it can be a #class("Condition") object, that allow to add more complexity to such conditions.
#class("Condition") objects can be combined through `AND` , `OR` and `XOR` logical binary operators to create a single stopping criterion object that can be passed to the #class("Inversion").

The #class("Inversion") object can also produce an _inversion log_, as a table that is printed to the user to provide information about each iteration. The inversion log can be easily customized, or even replaced entirely by a custom one.

// Other smaller parts:
// - Condition classes
//

// Allow to easily generalize the creation of arbitrary objective functions without any rigid assumptions.
// Enable usage of general minimizers (like scipy ones).
// Set up an inversion through a new `Inversion` class.

// Prefer verbosity over magic behaviours.
// Better definition of stopping criterion.

// Allow users to easily extend the codebase and plug their custom code into the existing inversion framework.
// Easy to combine custom misfits and regularizations with the built-in objective function classes.

// Make minimizers and Inversion class to be iterable: so users can insert custom code in between iterations without the need to modify the codebase.

// Stopping criterion.
// Inverison printout (aka log), can be easily extended and customized.
// Use of abstract classes and minimal interfaces.

// Details on the new design:
// - Objective functions
// - Minimization
// - The Inversion class

// Simple example of the workflow as in code?


== Example

Here we show a simple example on how to run a 2D DC-IP inversion with a _beta cooling_ technique using the new inversion framework.

```python
# Define the objective function
# -----------------------------
# Define the data misfit for a 2D DC-IP simulation.
data_misfit = DataMisfit(
    data, uncertainty, dcip_simulation
)
# Define a regularization with a smallness
# and two flatness terms.
regularization = (
    Smallness(mesh)
    + 0.2 * Flatness(mesh, direction="x")
    + 0.2 * Flatness(mesh, direction="y")
)
# Initial value for the trade-off parameter.
beta = 1e6
# Define the objective function.
phi = data_misfit + beta * regularization

# Define the inversion
# --------------------
# Define a stopping criterion as a chi factor of 1.
stopping_criterion = ChiTarget(
    data_misfit, chi_target=1.0
)
# Directive to cool down beta after each iteration.
beta_cooler = MultiplierCooler(regularization)
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

We have created a prototype of SimPEG's new inversion framework that is more modular, extensible, flexible, and interactive.
The prototype is available in https://github.com/simpeg/inversion-design-ideas under the open-source MIT License.
Our goal is to progressively incorporate it into SimPEG in the near future: first as under an experimental submodule, and then make it the preferred way to run inversions.
We invite everyone to experiment with it and provide feedback.
