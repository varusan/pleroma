(window.webpackJsonp=window.webpackJsonp||[]).push([[21],{693:function(t,a,e){"use strict";e.r(a),e.d(a,"default",function(){return y});var s,o,n,r=e(1),c=e(7),i=e(2),u=(e(3),e(20)),p=e(24),d=e(5),l=e.n(d),h=e(26),f=e.n(h),b=e(291),m=e(56),j=e(6),v=e(896),O=e(642),I=e(644),w=e(643),y=Object(u.connect)(function(t,a){return{accountIds:t.getIn(["user_lists","favourited_by",a.params.statusId])}})((n=o=function(t){function a(){return t.apply(this,arguments)||this}Object(c.a)(a,t);var e=a.prototype;return e.componentWillMount=function(){this.props.dispatch(Object(m.l)(this.props.params.statusId))},e.componentWillReceiveProps=function(t){t.params.statusId!==this.props.params.statusId&&t.params.statusId&&this.props.dispatch(Object(m.l)(t.params.statusId))},e.render=function(){var t=this.props,a=t.shouldUpdateScroll,e=t.accountIds;if(!e)return Object(r.a)(O.a,{},void 0,Object(r.a)(b.a,{}));var s=Object(r.a)(j.b,{id:"empty_column.favourites",defaultMessage:"No one has favourited this toot yet. When someone does, they will show up here."});return Object(r.a)(O.a,{},void 0,Object(r.a)(I.a,{}),Object(r.a)(w.a,{scrollKey:"favourites",shouldUpdateScroll:a,emptyMessage:s},void 0,e.map(function(t){return Object(r.a)(v.a,{id:t,withNote:!1},t)})))},a}(p.a),Object(i.a)(o,"propTypes",{params:l.a.object.isRequired,dispatch:l.a.func.isRequired,shouldUpdateScroll:l.a.func,accountIds:f.a.list}),s=n))||s}}]);
//# sourceMappingURL=favourites.js.map