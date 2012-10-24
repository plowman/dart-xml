part of xml_utils_prujohn;

/**
* Represents a queryable collection of [XmlNode] elements.
*/
class XmlCollection<E extends XmlNode> implements Collection<E> {
  final List<E> _collection;

  XmlCollection._internal()
  :
    _collection = new List<E>();

  XmlCollection._from(Collection<E> list)
  :
    _collection = new List<E>()
  {
    _collection.addAll(list);
  }

  /**
   * Check whether the collection contains an element equal to [element].
   */
  bool contains(E element) => _collection.contains(element);

  /**
   * Returns the last element of the [XmlCollection], or throws an out of bounds
   * exception if the [XmlCollection] is empty.
   */
  E last() => _collection.last();

  /**
   * Returns the first index of [element] in this [XmlCollection].
   * Searches this [XmlCollection] from index [start] to the length of the
   * [XmlCollection]. Returns -1 if [element] is not found.
   */
  indexOf(E element) => _collection.indexOf(element);


  /**
   * Reduce a collection to a single value by iteratively combining each element
   * of the collection with an existing value using the provided function.
   * Use [initialValue] as the initial value, and the function [combine] to
   * create a new value from the previous one and an element.
   *
   * Example of calculating the sum of a collection:
   *
   *   collection.reduce(0, (prev, element) => prev + element);
   */
  Dynamic reduce(Dynamic initialValue,
                 Dynamic combine(Dynamic previousValue, E element))
  => _collection.reduce(initialValue, combine);



  /**
   * Returns the element at the given [index] in the [XmlCollection] or throws
   * an [IndexOutOfRangeException] if [index] is out of bounds.
   */
  E operator [](int index) => _collection[index];

  void _add(E element) => _collection.add(element);

  void _removeRange(int start, int length) =>
      _collection.removeRange(start, length);

  /**
   * Applies the function [f] to each element of this collection.
   */
  void forEach(void f(E element)) => _collection.forEach(f);

  /**
   * Returns a new [XmlCollection] with the elements [: f(e) :]
   * for each element [e] of this collection.
   *
   * Note on typing: the return type of f() could be an arbitrary
   * type and consequently the returned collection's
   * typeis Collection.
   */
  XmlCollection map(f(E element)) =>
      new XmlCollection._from(_collection.map(f));

  /**
   * Returns a new [XmlCollection] with the elements of this collection
   * that satisfy the predicate [f].
   *
   * An element satisfies the predicate [f] if [:f(element):]
   * returns true.
   */
  XmlCollection<E> filter(bool f(E element))
  => new XmlCollection._from(_collection.filter(f));

  XmlCollection<XmlElement> allElements() =>
      new XmlCollection._from(_collection.filter((n) => n is XmlElement));

  /**
   * Returns true if every elements of this collection satisify the
   * predicate [f]. Returns false otherwise.
   */
  bool every(bool f(E element)) => _collection.every(f);

  /**
   * Returns true if one element of this collection satisfies the
   * predicate [f]. Returns false otherwise.
   */
  bool some(bool f(E element)) => _collection.some(f);

  /**
   * Returns true if there is no element in this collection.
   */
  bool isEmpty() => _collection.isEmpty();

  /**
   * Returns the number of elements in this collection.
   */
  int get length => _collection.length;

  /**
   * Returns an [Iterator] that iterates over this [Iterable] object.
   */
  Iterator<E> iterator() => _collection.iterator();


  /**
  * Returns the first node in the tree that matches the given [queryOn]
  * parameter.
  *
  * ## Usage ##
  * * query('tagName') // returns first occurance matching tag name.
  * * query(XmlNodeType.CDATA) // returns first occurance of element matching
  * the given node type (CDATA node in this example).
  * * query({'attributeName':'attributeValue'}) // returns the first occurance
  * of any [XmlElement] where the given attributes/values are found.
  */
  XmlCollection<XmlNode> query(queryOn){
    XmlCollection<XmlNode> list = new XmlCollection._internal();

    if (queryOn is String){
      for (final node in this.allElements()){
        _queryNameInternal(queryOn, list, node);
        if (!list.isEmpty()) break;
      }
    }else if (queryOn is XmlNodeType){
      for (final node in this){
        _queryNodeTypeInternal(queryOn, list, node);
        if (!list.isEmpty()) break;
      }
    }else if (queryOn is Map){
      for (final node in this.allElements()){
        _queryAttributeInternal(queryOn, list, node);
        if (!list.isEmpty()) break;
      }
    }

    return list;
  }


  void _queryAttributeInternal(Map aMap,
                               XmlCollection<XmlNode> list,
                               XmlElement n){
    bool checkAttribs(){
      var succeed = true;

      //TODO needs better implementation to
      //break out on first false
      aMap.forEach((k, v){
        if (succeed && n.attributes.containsKey(k)) {
          if (n.attributes[k] != v) succeed = false;
        }else{
          succeed = false;
        }
      });

      return succeed;
    }

    if (checkAttribs()){
      list._add(n);
      return;
    }else{
      if (n.hasChildren){
        n.children
        .allElements()
        .forEach((el){
          if (!list.isEmpty()) return;
          (el as XmlElement)._queryAttributeInternal(aMap, list);
        });
      }
    }
  }

  void _queryNodeTypeInternal(XmlNodeType nodeType,
                              XmlCollection<XmlNode> list,
                              XmlNode node){
    if (node.type == nodeType){
      list._add(node);
      return;
    }else{
      if ((node as XmlElement).hasChildren){
        node.children
          .forEach((el){
            if (!list.isEmpty()) return;
            if (el is XmlElement){
              el._queryNodeTypeInternal(nodeType, list);
            }else{
              if (el.type == nodeType){
                list._add(el);
                return;
              }
            }
          });
      }
    }
  }

  void _queryNameInternal(String tagName, XmlCollection<XmlNode> list,
                          XmlElement element){

    if (element.name == tagName){
      list._add(element);
      return;
    }else{
      if (element.hasChildren){
        element.children
          .allElements()
          .forEach((el){
            if (!list.isEmpty()) return;
            el._queryNameInternal(tagName, list);
          });
      }
    }
  }

  /**
  * Returns a list of nodes in the tree that match the given [queryOn]
  * parameter.
  *
  * ## Usage ##
  * * query('tagName') = returns first occurance matching tag name.
  * * query(XmlNodeType.CDATA) // returns first occurance of element matching
  * the given node type (CDATA node in this example).
  */
  XmlCollection<XmlNode> queryAll(queryOn){
    var list = new XmlCollection<XmlNode>._internal();

    if (queryOn is String){
      for (final node in this.allElements()){
        _queryAllNamesInternal(queryOn, list, node);
      }
    }else if (queryOn is XmlNodeType){
      for (final node in this){
        _queryAllNodeTypesInternal(queryOn, list, node);
      }
    }else if (queryOn is Map){
      for (final node in this.allElements()){
        _queryAllAttributesInternal(queryOn, list, node);
      }
    }

    return list;
  }

  void _queryAllAttributesInternal(Map aMap,
                                   XmlCollection<XmlNode> list,
                                   XmlElement element){
    bool checkAttribs(){
      var succeed = true;

      //TODO needs better implementation to
      //break out on first false
      aMap.forEach((k, v){
        if (succeed && element.attributes.containsKey(k)) {
          if (element.attributes[k] != v) succeed = false;
        }else{
          succeed = false;
        }
      });

      return succeed;
    }

    if (checkAttribs()){
      list._add(element);
    }else{
      if (element.hasChildren){
        element.children
        .allElements()
        .forEach((el){
          el._queryAttributeInternal(aMap, list);
        });
      }
    }
  }

  void _queryAllNodeTypesInternal(XmlNodeType nodeType,
                                  XmlCollection<XmlNode> list,
                                  XmlNode node){
    if (node.type == nodeType){
      list._add(node);
    }else{
      if ((node as XmlElement).hasChildren){
        node.children
          .forEach((el){
            if (el is XmlElement){
              el._queryAllNodeTypesInternal(nodeType, list);
            }else{
              if (el.type == nodeType){
                list._add(el);
              }
            }
          });
      }
    }
  }

  _queryAllNamesInternal(String tagName,
                         XmlCollection<XmlNode> list,
                         XmlElement element){
    if (element.name == tagName){
      list._add(element);
    }

    if (element.hasChildren){
      element.children
      .filter((el) => el is XmlElement)
      .forEach((el){
        el._queryAllNamesInternal(tagName, list);
      });
    }
  }

  String toString() => _collection.toString();
}
