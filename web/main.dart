import 'dart:html';
import 'dart:async';
import 'package:json_object/json_object.dart';

//DocumentFragment is a unique kind of element reserved for template elements.
//These elements have no parent node yet and are not part of the DOM.
DocumentFragment _frag;

Element _view;

void main() {
  _view = querySelector('#deals');
  _frag = (querySelector('template') as TemplateElement).content;
  render();
}


class Deal {
  HeadingElement city;
  ParagraphElement description;
  HeadingElement date;
  HeadingElement price;
  ImageElement image;
  AnchorElement button;
  DivElement element;

  Deal() { // constructor

    element = new Element.div();
    element.nodes.add(_frag.clone(true));
    city = element.querySelector('h3');
    date = element.querySelector('h4');
    price = element.querySelector('h5');
    image = element.querySelector('img');
    button = element.querySelector('a');
    description = element.querySelector('p');
    //dynamically add an Anchor
    button = new Element.a();
    button.setAttribute('class', 'btn btn-info');
    button.text = "Buy";
    element.querySelector('.deal-box').children.add(button);
  }

}

Future render() async {

  String result = await HttpRequest.getString('deals.json');
  JsonObject response = new JsonObject.fromJsonString(result);
  List dealVOs = response.deals;

  dealVOs.forEach((dealVO) {
    // aDeal is a div element created
    Deal aDeal = new Deal();
    aDeal.city.text = '${dealVO.city_departure} to ${dealVO.city_arrival}';
    aDeal.date.text = dealVO.date;
    aDeal.price.text = dealVO.price;
    aDeal.description.text = dealVO.description;
    aDeal.image.src = dealVO.image;
    aDeal.button.href = dealVO.url;
    // append  a div element to the _view
    _view.children.add(aDeal.element);
  });

}
